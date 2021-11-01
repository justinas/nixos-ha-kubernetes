{ pkgs ? import (import ./nixpkgs.nix) { } }:
let
  colmena = import
    (fetchTarball {
      url = "https://github.com/zhaofengli/colmena/archive/86eeeece3cb13c12476a3e016903f6fb0927fe08.tar.gz";
      sha256 = "1anvabqi1m5wz6x2i07gdh4k1v2h9lxhvq3j2zzybsdr1i2vvsbd";
    })
    { };
  myTerraform = pkgs.terraform_0_15.withPlugins (tp: [ tp.libvirt ]);
  ter = pkgs.writeShellScriptBin "ter" ''
    ${myTerraform}/bin/terraform $@ && \
      ${myTerraform}/bin/terraform show -json > show.json
  '';

  ci-lint = pkgs.writeShellScriptBin "ci-lint" ''
    echo Checking the formatting of Nix files
    ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check **/*.nix

    echo

    echo Checking the formatting of Terraform files
    ${myTerraform}/bin/terraform fmt -check -recursive
  '';

  k = pkgs.writeShellScriptBin "k" ''
    kubectl --kubeconfig certs/generated/kubernetes/admin.kubeconfig $@
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
    ci-lint
    k
    make-boot-image
    make-certs
    ter
  ];
}
