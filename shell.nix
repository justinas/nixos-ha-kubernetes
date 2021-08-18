{ pkgs ? import (import ./nixpkgs.nix) { } }:
let
  colmena = import
    (fetchTarball {
      url = "https://github.com/zhaofengli/colmena/archive/c6ac93152cbfe012013e994c5d1108e5008742d6.tar.gz";
      sha256 = "0zljn06yszzy1ghzfd3hyzxwfr9b26iydfgyqwag7h0d8bg2mgjr";
    })
    { };
  myTerraform = pkgs.terraform_0_15.withPlugins (tp: [ tp.libvirt ]);
  ter = pkgs.writeShellScriptBin "ter" ''
    ${myTerraform}/bin/terraform $@ && \
      ${myTerraform}/bin/terraform show -json > show.json
  '';

  k = pkgs.writeShellScriptBin "k" ''
    kubectl --kubeconfig certs/generated/kubernetes/admin/config $@
  '';

  make-boot-image = pkgs.writeShellScriptBin "make-boot-image" ''
    nix-build -o boot/image boot/image.nix
  '';

  make-certs = pkgs.writeShellScriptBin "make-certs" ''
    $(nix-build --no-out-link certs)/bin/generate-certs
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # software for deployment
    colmena
    jq
    libxslt
    myTerraform

    # software for testing
    etcd
    kubectl

    # scripts
    k
    make-boot-image
    make-certs
    ter
  ];
}
