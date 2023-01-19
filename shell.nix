{ pkgs ? import (import ./nixpkgs.nix) { } }:
let
  myTerraform = pkgs.terraform.withPlugins (tp: [ tp.libvirt ]);
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
    openssl

    # scripts
    ci-lint
    k
    make-boot-image
    make-certs
    ter
  ];
}
