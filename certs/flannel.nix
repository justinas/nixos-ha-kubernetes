{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ./utils.nix { }) getAltNames mkCsr;

  etcdClientCsr = mkCsr "etcd-client" {
    cn = "flannel";
    altNames = getAltNames "worker";
  };

in
''
  mkdir -p $out/flannel

  pushd $out/etcd > /dev/null
  genCert client ../flannel/etcd-client ${etcdClientCsr}
  popd > /dev/null
''
