{ resourcesByRole, ... }:
let
  inherit (import ../../utils.nix) nodeIP;

  # TODO: point to virtual IP instead
  controlPlaneIP = nodeIP (builtins.head (resourcesByRole "controlplane"));
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
      server = "https://${controlPlaneIP}:6443";
    };
  };
}
