{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ../resources.nix { }) resourcesByRole;
  inherit (import ../utils.nix) nodeIP;
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

  workerCsrs = map
    (r: {
      name = r.values.name;
      csr = mkCsr "${r.values.name}" {
        cn = "system:node:${r.values.name}";
        organization = "system:nodes";
        # TODO: unify with getAltNames?
        altNames = [ r.values.name (nodeIP r) ];
      };
    })
    (resourcesByRole "worker");

  workerScripts = map
    (csr: '' ${cfssl}/bin/cfssl gencert -ca ../ca.pem -ca-key ../ca-key.pem -config ${caConfig} -profile client ${csr.csr} \
      | ${cfssl}/bin/cfssljson -bare ${csr.name}
  '')
    workerCsrs;
in
''
  mkdir -p $out/kubernetes/{apiserver,admin,kubelet}
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

  popd > /dev/null

  pushd kubelet > /dev/null

  ${builtins.concatStringsSep "\n" workerScripts}

  popd > /dev/null

  popd > /dev/null
''
