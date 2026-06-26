{
  imports = [ ./boot.nix ./login.nix ];
  networking.nftables.enable = true;
  system.stateVersion = "26.05";
}
