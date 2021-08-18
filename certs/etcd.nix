{ pkgs, cfssl }:
let
  inherit (pkgs.callPackage ./utils.nix { }) caConfig getAltNames mkCsr;

  caCsr = mkCsr "etcd-ca" { cn = "etcd-ca"; };
  serverCsr = mkCsr "etcd-server" {
    cn = "etcd";
    altNames = getAltNames "etcd";
  };
  clientCsr = mkCsr "etcd-client" {
    cn = "etcd-client";
    altNames = getAltNames "etcd";
  };
in
''
  mkdir -p $out/etcd
  pushd $out/etcd > /dev/null

  ${cfssl}/bin/cfssl gencert -initca ${caCsr} \
    | ${cfssl}/bin/cfssljson -bare ca
  ${cfssl}/bin/cfssl gencert -ca ca.pem -ca-key ca-key.pem -config ${caConfig} -profile server ${serverCsr} \
    | ${cfssl}/bin/cfssljson -bare server
  ${cfssl}/bin/cfssl gencert -ca ca.pem -ca-key ca-key.pem -config ${caConfig} -profile client ${clientCsr} \
    | ${cfssl}/bin/cfssljson -bare client

  popd > /dev/null
''
