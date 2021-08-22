{ name, resourcesByRole, ... }:
let
  inherit (import ../../utils.nix) nodeIP;

  # TODO: point to virtual IP instead
  controlPlaneIP = nodeIP (builtins.head (resourcesByRole "controlplane"));
in
{
  deployment.keys = {
    "ca.pem" = {
      keyFile = ../../certs/generated/kubernetes/ca.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "apiserver-client.pem" = {
      keyFile = ../../certs/generated/kubernetes/kubelet + "/${name}.pem";
      destDir = "/var/lib/secrets/kubernetes/kubelet";
      user = "kubernetes";
    };

    "apiserver-client-key.pem" = {
      keyFile = ../../certs/generated/kubernetes/kubelet + "/${name}-key.pem";
      destDir = "/var/lib/secrets/kubernetes/kubelet";
      user = "kubernetes";
    };
  };

  services.kubernetes.kubelet = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/kubelet/apiserver-client.pem";
      keyFile = "/var/lib/secrets/kubernetes/kubelet/apiserver-client-key.pem";
      server = "https://${controlPlaneIP}:6443";
    };
  };
}
