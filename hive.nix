let
  pkgs = import (import ./nixpkgs.nix) { };
  lib = pkgs.lib;

  inherit (pkgs.callPackage ./resources.nix { }) resources resourcesByRole;
  inherit (import ./utils.nix) nodeIP;
  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  etcdConf = { ... }: {
    imports = [ ./modules/etcd.nix ];
    deployment.tags = [ "etcd" ];
  };
in
{
  meta = {
    nixpkgs = import (import ./nixpkgs.nix);
  };

  defaults = { name, self, ... }: {
    imports = [
      ./modules/autoresources.nix
      ./modules/base.nix
    ];

    deployment.targetHost = nodeIP self;
    networking.hostName = name;
  };
}
  // builtins.listToAttrs (map (h: { name = h; value = etcdConf; }) etcdHosts)
