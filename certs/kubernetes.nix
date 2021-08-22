{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ../resources.nix { }) resourcesByRole;
  inherit (import ../utils.nix) nodeIP;
  inherit (pkgs.callPackage ./utils.nix { }) getAltNames mkCsr;

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
  mkdir -p $out/kubernetes/{apiserver,kubelet}

  pushd $out/etcd > /dev/null

  genCert client ../kubernetes/apiserver/etcd-client ${etcdClientCsr}

  popd > /dev/null

  pushd $out/kubernetes > /dev/null

  genCa ${caCsr}

  genCert server apiserver/server ${apiServerCsr}

  genCert client admin ${adminCsr}

  ${builtins.concatStringsSep "\n" workerScripts}

  popd > /dev/null
''
