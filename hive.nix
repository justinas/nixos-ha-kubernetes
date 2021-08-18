let
  pkgs = import (import ./nixpkgs.nix) { };
  lib = pkgs.lib;

  inherit (pkgs.callPackage ./resources.nix { }) resources resourcesByRole;
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  etcdConf = { ... }: {
    deployment.tags = [ "etcd" ];
  };
in
{
  meta = {
    nixpkgs = import (import ./nixpkgs.nix);
  };

  defaults = { name, self, ... }:
    let
      interface = (builtins.head self.values.network_interface);
      ip = (builtins.head interface.addresses);
    in
    {
      imports = [
        ./modules/autoresources.nix
        ./modules/base.nix
      ];

      deployment.targetHost = ip;
      networking.hostName = name;
    };
}
  // builtins.listToAttrs (map (h: { name = h; value = etcdConf; }) etcdHosts)
