{ lib, resourcesByRole, ... }:
let
  etcdServers = map (r: "https://${r.values.name}:2379") (resourcesByRole "etcd");

  mkSecret = filename: {
    keyFile = ../../certs/generated/kubernetes/apiserver + "/${filename}";
    destDir = "/var/lib/secrets/kubernetes/apiserver";
    user = "kubernetes";
  };

  corednsPolicies = map
    (r: {
      apiVersion = "abac.authorization.kubernetes.io/v1beta1";
      kind = "Policy";
      spec = {
        user = "system:coredns";
        namespace = "*";
        resource = r;
        readonly = true;
      };
    }) [ "endpoints" "services" "pods" "namespaces" ]
  ++ lib.singleton
    {
      apiVersion = "abac.authorization.kubernetes.io/v1beta1";
      kind = "Policy";
      spec = {
        user = "system:coredns";
        namespace = "*";
        resource = "endpointslices";
        apiGroup = "discovery.k8s.io";
        readonly = true;
      };
    };
in
{
  deployment.keys = {
    "server.pem" = mkSecret "server.pem";
    "server-key.pem" = mkSecret "server-key.pem";

    "kubelet-client.pem" = mkSecret "kubelet-client.pem";
    "kubelet-client-key.pem" = mkSecret "kubelet-client-key.pem";

    "etcd-ca.pem" = {
      keyFile = ../../certs/generated/etcd/ca.pem;
      destDir = "/var/lib/secrets/kubernetes/apiserver";
      user = "kubernetes";
    };
    "etcd-client.pem" = mkSecret "etcd-client.pem";
    "etcd-client-key.pem" = mkSecret "etcd-client-key.pem";
  };

  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.kubernetes.apiserver = {
    enable = true;
    serviceClusterIpRange = "10.32.0.0/24";

    # Using ABAC for CoreDNS running outside of k8s
    # is more simple in this case than using kube-addon-manager
    authorizationMode = [ "RBAC" "Node" "ABAC" ];
    authorizationPolicy = corednsPolicies;

    etcd = {
      servers = etcdServers;
      caFile = "/var/lib/secrets/kubernetes/apiserver/etcd-ca.pem";
      certFile = "/var/lib/secrets/kubernetes/apiserver/etcd-client.pem";
      keyFile = "/var/lib/secrets/kubernetes/apiserver/etcd-client-key.pem";
    };

    clientCaFile = "/var/lib/secrets/kubernetes/ca.pem";

    kubeletClientCaFile = "/var/lib/secrets/kubernetes/ca.pem";
    kubeletClientCertFile = "/var/lib/secrets/kubernetes/apiserver/kubelet-client.pem";
    kubeletClientKeyFile = "/var/lib/secrets/kubernetes/apiserver/kubelet-client-key.pem";

    # TODO: separate from server keys
    serviceAccountKeyFile = "/var/lib/secrets/kubernetes/apiserver/server.pem";
    serviceAccountSigningKeyFile = "/var/lib/secrets/kubernetes/apiserver/server-key.pem";

    tlsCertFile = "/var/lib/secrets/kubernetes/apiserver/server.pem";
    tlsKeyFile = "/var/lib/secrets/kubernetes/apiserver/server-key.pem";
  };
}
