{ pkgs, resourcesByRole, self, ... }:
let
  inherit (import ../../consts.nix) virtualIP;
  inherit (import ../../utils.nix) nodeIP;
in
{
  deployment.keys = {
    "coredns-kube.pem" = {
      keyFile = ../../certs/generated/coredns/coredns-kube.pem;
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "coredns-kube-key.pem" = {
      keyFile = ../../certs/generated/coredns/coredns-kube-key.pem;
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
    "kube-ca.pem" = {
      keyFile = ../../certs/generated/kubernetes/ca.pem;
      destDir = "/var/lib/secrets/coredns";
      user = "coredns";
    };
  };

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        kubernetes cluster.local {
          endpoint https://${virtualIP}
          tls /var/lib/secrets/coredns/coredns-kube.pem /var/lib/secrets/coredns/coredns-kube-key.pem /var/lib/secrets/coredns/kube-ca.pem
          pods verified
        }
        forward . 1.1.1.1:53 1.0.0.1:53
      }
    '';
  };

  services.kubernetes.kubelet.clusterDns = nodeIP self;

  networking.firewall.interfaces.mynet.allowedTCPPorts = [ 53 ];
  networking.firewall.interfaces.mynet.allowedUDPPorts = [ 53 ];

  users.groups.coredns = { };
  users.users.coredns = {
    group = "coredns";
    isSystemUser = true;
  };
}
