{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ./utils.nix { }) caConfig getAltNames mkCsr;

  caCsr = mkCsr "kubernetes-ca" { cn = "kubernetes-ca"; };

  apiServerCsr = mkCsr "kube-api-server" {
    cn = "kubernetes";
    altNames = getAltNames "controlplane" ++
      [ "kubernetes" "kubernetes.default" "kubernetes.default.svc" "kubernetes.default.svc.cluster" "kubernetes.svc.cluster.local" ];
  };

  adminCsr = mkCsr "admin" {
    cn = "admin";
    organization = "system:masters";
  };

  etcdClientCsr = mkCsr "etcd-client" {
    cn = "kubernetes";
    altNames = getAltNames "controlplane";
  };
in
''
  mkdir -p $out/kubernetes/{apiserver,admin}
  pushd $out/kubernetes > /dev/null

  ${cfssl}/bin/cfssl gencert -initca ${caCsr} \
    | ${cfssl}/bin/cfssljson -bare ca

  pushd apiserver > /dev/null

  ${cfssl}/bin/cfssl gencert -ca ../ca.pem -ca-key ../ca-key.pem -config ${caConfig} -profile server ${apiServerCsr} \
    | ${cfssl}/bin/cfssljson -bare server

  ${cfssl}/bin/cfssl gencert -ca ../../etcd/ca.pem -ca-key ../../etcd/ca-key.pem -config ${caConfig} -profile client ${etcdClientCsr} \
    | ${cfssl}/bin/cfssljson -bare etcd-client

  popd > /dev/null

  pushd admin > /dev/null

  ${cfssl}/bin/cfssl gencert -ca ../ca.pem -ca-key ../ca-key.pem -config ${caConfig} -profile server ${adminCsr} \
    | ${cfssl}/bin/cfssljson -bare client

  ${kubectl}/bin/kubectl --kubeconfig config config set-credentials admin \
      --client-certificate=client.pem \
      --client-key=client-key.pem
  ${kubectl}/bin/kubectl --kubeconfig config config set-cluster virt \
      --certificate-authority=../ca.pem \
      --server=https://10.240.0.117:6443 # TODO: dynamic or replace with virtual IP
  ${kubectl}/bin/kubectl --kubeconfig config config set-context virt --user admin --cluster virt
  ${kubectl}/bin/kubectl --kubeconfig config config use-context virt


  popd > /dev/null
''
