{ pkgs ? import (import ../nixpkgs.nix) { }
, cfssl ? pkgs.cfssl
}:

# Only use Nix to generate the certificate generation ( :) ) script.
# That way, we avoid certificates ending up in the world-readable Nix store
pkgs.writeShellScriptBin "generate-certs" ''
  set -e

  out=./certs/generated

  [ ! -d "$out" ] || (echo "./certs/generated exists, refusing to overwrite its contents" && exit 1)
  ${pkgs.callPackage ./etcd.nix { }}
''
