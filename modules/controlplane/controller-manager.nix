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
      certFile = "/var/lib/secrets/kubernetes/controller-manager.pem";
      keyFile = "/var/lib/secrets/kubernetes/controller-manager-key.pem";
      server = "https://${virtualIP}";
    };

    # TODO: separate from server keys?
    serviceAccountKeyFile = "/var/lib/secrets/kubernetes/apiserver/server-key.pem";
  };
}
