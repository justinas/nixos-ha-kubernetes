{ pkgs, cfssl }:
let
  inherit (pkgs.callPackage ./utils.nix { }) getAltNames mkCsr;

  caCsr = mkCsr "etcd-ca" { cn = "etcd-ca"; };
  serverCsr = mkCsr "etcd-server" {
    cn = "etcd";
    altNames = getAltNames "etcd";
  };
  peerCsr = mkCsr "etcd-peer" {
    cn = "etcd-peer";
    altNames = getAltNames "etcd";
  };
in
''
  mkdir -p $out/etcd

  pushd $out/etcd > /dev/null

  genCa ${caCsr}
  genCert server server ${serverCsr}
  genCert peer peer ${peerCsr}

  popd > /dev/null
''
