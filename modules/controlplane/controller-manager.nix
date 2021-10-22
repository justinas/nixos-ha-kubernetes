{ resourcesByRole, ... }:
let
  inherit (import ../../consts.nix) virtualIP;
in
{
  deployment.keys = {
    "controller-manager.pem" = {
      keyFile = ../../certs/generated/kubernetes/controller-manager.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
    "controller-manager-key.pem" = {
      keyFile = ../../certs/generated/kubernetes/controller-manager-key.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  services.kubernetes.controllerManager = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/controller-manager.pem";
      keyFile = "/var/lib/secrets/kubernetes/controller-manager-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
