{ lib, pkgs, ... }:
let
  domain = "k8s.local";

  inherit (pkgs.callPackage ../resources.nix { }) resourcesByRole;
  inherit (import ../utils.nix) nodeIP;

  writeJSONText = name: obj: pkgs.writeText "${name}.json" (builtins.toJSON obj);

  csrDefaults = {
    key = {
      algo = "rsa";
      size = 2048;
    };
  };
in
{
  # Get IP/DNS alternative names for all servers of this role.
  # We currently use the same certificates for all replicas of a role (where possible),
  # so, for example, etcd certificate will have alt names:
  # etcd1, etcd2, etcd3, 10.240.0.xx1, 10.240.0.xx2, 10.240.0.xx3
  getAltNames = role:
    let
      hosts = map (r: r.values.name) (resourcesByRole role);
      ips = map nodeIP (resourcesByRole role);
    in
    hosts ++ (map (h: "${h}.${domain}") hosts) ++ ips;

  # Form a CSR request, as expected by cfssl
  mkCsr = name: { cn, altNames ? [ ], organization ? null }:
    writeJSONText name (lib.attrsets.recursiveUpdate csrDefaults {
      CN = cn;
      hosts = [ cn ] ++ altNames;
      names = if organization == null then null else [
        { "O" = organization; }
      ];
    });
}
