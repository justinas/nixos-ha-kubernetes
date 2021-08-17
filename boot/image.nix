# Build a basic boot image to provision a NixOS virtual machine
# Based on: https://gist.github.com/tarnacious/f9674436fff0efeb4bb6585c79a3b9ff
{ pkgs ? import (import ../nixpkgs.nix) { } }:
let config = { config, lib, modulesPath, pkgs, ... }:
  {
    imports = [
      ../modules/base.nix
    ];

    config = {
      system.build.qcow = import "${toString modulesPath}/../lib/make-disk-image.nix" {
        inherit config lib pkgs;
        diskSize = 8192;
        format = "qcow2";
      };
    };
  };
in
(pkgs.nixos config).qcow
