{ resourcesByRole, ... }:
let
  inherit (import ../../utils.nix) nodeIP;
  backends = map
    (r: "server ${r.values.name} ${nodeIP r}:6443")
    (resourcesByRole "controlplane");
in
{
  services.haproxy = {
    enable = true;
    config = ''
      defaults
        timeout connect 10s

      frontend k8s
        mode tcp
        bind *:443
        default_backend controlplanes

      backend controlplanes
        mode tcp
        ${builtins.concatStringsSep "\n  " backends}
    '';
  };
  networking.firewall.allowedTCPPorts = [ 443 ];
}
