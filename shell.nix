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

  make-boot-image = pkgs.writeShellScriptBin "make-boot-image" ''
    nix-build -o boot/image boot/image.nix
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # software
    colmena
    jq
    libxslt
    myTerraform

    # scripts
    make-boot-image
    ter
  ];
}
