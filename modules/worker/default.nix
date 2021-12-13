{ config, name, resourcesByRole, ... }:
let
  inherit (import ../../consts.nix) virtualIP;
in
{
  imports = [ ./coredns.nix ./flannel.nix ];

  deployment.keys = {
    "ca.pem" = {
      keyFile = ../../certs/generated/kubernetes/ca.pem;
      destDir = "/var/lib/secrets/kubernetes";
      user = "kubernetes";
      permissions = "0644";
    };

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

  services.kubernetes.clusterCidr = "10.200.0.0/16";

  services.kubernetes.kubelet = rec {
    enable = true;
    unschedulable = false;
    kubeconfig = rec {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = tlsCertFile;
      keyFile = tlsKeyFile;
      server = "https://${virtualIP}";
    };
    clientCaFile = "/var/lib/secrets/kubernetes/ca.pem";
    tlsCertFile = "/var/lib/secrets/kubernetes/kubelet.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/kubelet-key.pem";

    # Copied from https://github.com/NixOS/nixpkgs/blob/1d0f825944402c43ebb51dd89511d62a9d3257d5/nixos/tests/kubernetes/base.nix#L64-L70
    # For some reason helps with https://github.com/justinas/nixos-ha-kubernetes/issues/5
    # TODO: try to remove after updating to Kubernetes v1.23
    extraOpts = ''\
      --cgroups-per-qos=false \
      --enforce-node-allocatable="" \
    '';
  };

  services.kubernetes.proxy = {
    enable = true;
    kubeconfig = {
      caFile = "/var/lib/secrets/kubernetes/ca.pem";
      certFile = "/var/lib/secrets/kubernetes/proxy.pem";
      keyFile = "/var/lib/secrets/kubernetes/proxy-key.pem";
      server = "https://${virtualIP}";
    };
  };
}
