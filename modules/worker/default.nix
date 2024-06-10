{ config, name, resourcesByRole, ... }:
let
  inherit (import ../../consts.nix) virtualIP;
in
{
  imports = [ ../kubernetes.nix ./coredns.nix ./flannel.nix ];

  deployment.keys = {
    "kubelet.pem" = {
      keyFile = ../../certs/generated/kubernetes/kubelet + "/${name}.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "kubelet-key.pem" = {
      keyFile = ../../certs/generated/kubernetes/kubelet + "/${name}-key.pem";
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "proxy.pem" = {
      keyFile = ../../certs/generated/kubernetes/proxy.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };

    "proxy-key.pem" = {
      keyFile = ../../certs/generated/kubernetes/proxy-key.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.kubernetes.kubelet.port
  ];

  services.kubernetes.kubelet = rec {
    enable = true;
    unschedulable = false;
    kubeconfig = rec {
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${virtualIP}";
    };
    tlsCertFile = "/var/lib/secrets/kubernetes/kubelet.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/kubelet-key.pem";
  };

  services.kubernetes.proxy = {
    enable = true;
    kubeconfig = {
      certFile = "/var/lib/secrets/kubernetes/proxy.pem";
      keyFile = "/var/lib/secrets/kubernetes/proxy-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
