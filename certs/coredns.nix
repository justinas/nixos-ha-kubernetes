{ pkgs, cfssl, kubectl }:
let
  inherit (pkgs.callPackage ./utils.nix { }) mkCsr;

  corednsKubeCsr = mkCsr "coredns" {
    cn = "system:coredns";
  };

in
''
  mkdir -p $out/coredns

  pushd $out/kubernetes > /dev/null
  genCert client ../coredns/coredns-kube ${corednsKubeCsr}
  popd > /dev/null
''
