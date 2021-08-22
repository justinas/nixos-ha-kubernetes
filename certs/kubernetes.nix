{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ../resources.nix { }) resourcesByRole;
  inherit (import ../utils.nix) nodeIP;
  inherit (pkgs.callPackage ./utils.nix { }) getAltNames mkCsr;

  # TODO: replace with virtual IP
  controlPlane1IP = nodeIP (builtins.head (resourcesByRole "controlplane"));

  caCsr = mkCsr "kubernetes-ca" {
    cn = "kubernetes-ca";
  };

  apiServerCsr = mkCsr "kube-api-server" {
    cn = "kubernetes";
    altNames = getAltNames "controlplane" ++
      [ "kubernetes" "kubernetes.default" "kubernetes.default.svc" "kubernetes.default.svc.cluster" "kubernetes.svc.cluster.local" ];
  };

  cmCsr = mkCsr "kube-controller-manager" {
    cn = "system:kube-controller-manager";
    organization = "system:kube-controller-manager";
  };

  adminCsr = mkCsr "admin" {
    cn = "admin";
    organization = "system:masters";
  };

  etcdClientCsr = mkCsr "etcd-client" {
    cn = "kubernetes";
    altNames = getAltNames "controlplane";
  };

  proxyCsr = mkCsr "kube-proxy" {
    cn = "system:kube-proxy";
    organization = "system:node-proxier";
  };

  workerCsrs = map
    (r: {
      name = r.values.name;
      csr = mkCsr r.values.name {
        cn = "system:node:${r.values.name}";
        organization = "system:nodes";
        # TODO: unify with getAltNames?
        altNames = [ r.values.name (nodeIP r) ];
      };
    })
    (resourcesByRole "worker");

  workerScripts = map (csr: "genCert client kubelet/${csr.name} ${csr.csr}") workerCsrs;
in
''
  mkdir -p $out/kubernetes/{apiserver,controller-manager,kubelet}

  pushd $out/etcd > /dev/null
  genCert client ../kubernetes/apiserver/etcd-client ${etcdClientCsr}
  popd > /dev/null

  pushd $out/kubernetes > /dev/null

  genCa ${caCsr}
  genCert server apiserver/server ${apiServerCsr}
  genCert client controller-manager ${cmCsr}
  genCert client proxy ${proxyCsr}
  genCert client admin ${adminCsr}

  ${builtins.concatStringsSep "\n" workerScripts}

  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-credentials admin \
      --client-certificate=admin.pem \
      --client-key=admin-key.pem
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-cluster virt \
      --certificate-authority=ca.pem \
      --server=https://${controlPlane1IP}:6443
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config set-context virt \
      --user admin \
      --cluster virt
  ${kubectl}/bin/kubectl --kubeconfig admin.kubeconfig config use-context virt > /dev/null

  popd > /dev/null
''
