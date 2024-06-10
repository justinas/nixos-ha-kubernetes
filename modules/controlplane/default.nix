{ ... }: {
  imports = [ ../kubernetes.nix ./apiserver.nix ./controller-manager.nix ./scheduler.nix ];
}
