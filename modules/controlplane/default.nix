{ ... }: {
  imports = [ ./apiserver.nix ./controller-manager.nix ./scheduler.nix ];

  deployment.keys."ca.pem" = {
    keyFile = ../../certs/generated/kubernetes/ca.pem;
    destDir = "/var/lib/secrets/kubernetes";
    user = "kubernetes";
  };

  services.kubernetes.clusterCidr = "10.200.0.0/16";
}
