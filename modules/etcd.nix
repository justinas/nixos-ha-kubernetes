{ lib, resources, resourcesByRole, self, ... }:
let
  inherit (import ../utils.nix) nodeIP;
  etcds = resourcesByRole "etcd";
  cluster = map (r: "${r.values.name}=https://${nodeIP r}:2380") etcds;

  mkSecret = filename: {
    keyFile = ../certs/generated/etcd + "/${filename}";
    destDir = "/var/lib/secrets/etcd";
    user = "etcd";
  };
in
{
  deployment.keys = {
    "ca.pem" = mkSecret "ca.pem";
    "peer.pem" = mkSecret "peer.pem";
    "peer-key.pem" = mkSecret "peer-key.pem";
    "server.pem" = mkSecret "server.pem";
    "server-key.pem" = mkSecret "server-key.pem";
  };

  networking.firewall.allowedTCPPorts = [ 2379 2380 ];

  services.etcd = {
    enable = true;

    advertiseClientUrls = [ "https://${nodeIP self}:2379" ];
    initialAdvertisePeerUrls = [ "https://${nodeIP self}:2380" ];
    initialCluster = lib.mkForce cluster;
    listenClientUrls = [ "https://${nodeIP self}:2379" "https://127.0.0.1:2379" ];
    listenPeerUrls = [ "https://${nodeIP self}:2380" "https://127.0.0.1:2380" ];

    clientCertAuth = true;

    certFile = "/var/lib/secrets/etcd/server.pem";
    keyFile = "/var/lib/secrets/etcd/server-key.pem";

    peerCertFile = "/var/lib/secrets/etcd/peer.pem";
    peerKeyFile = "/var/lib/secrets/etcd/peer-key.pem";

    peerTrustedCaFile = "/var/lib/secrets/etcd/ca.pem";
    trustedCaFile = "/var/lib/secrets/etcd/ca.pem";
  };
}
