{ resourcesByRole, ... }:
let
  inherit (import ../../consts.nix) virtualIP;
in
{
  deployment.keys = {
    "scheduler.pem" = {
      keyFile = ../../certs/generated/kubernetes/scheduler.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
    "scheduler-key.pem" = {
      keyFile = ../../certs/generated/kubernetes/scheduler-key.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  services.kubernetes.scheduler = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/scheduler.pem";
      keyFile = "/var/lib/secrets/kubernetes/scheduler-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
