{ pkgs ? import (import ../nixpkgs.nix) { }
, cfssl ? pkgs.cfssl
}:
let
  caConfig = pkgs.writeText "ca-config.json" ''
    {
      "signing": {
        "profiles": {
          "client": {
            "expiry": "87600h",
            "usages": ["signing", "key encipherment", "client auth"]
          },
          "peer": {
            "expiry": "87600h",
            "usages": ["signing", "key encipherment", "client auth", "server auth"]
          },
          "server": {
            "expiry": "8760h",
            "usages": ["signing", "key encipherment", "client auth", "server auth"]
          }
        }
      }
    }
  '';
in
# Only use Nix to generate the certificate generation ( :) ) script.
  # That way, we avoid certificates ending up in the world-readable Nix store
pkgs.writeShellScriptBin "generate-certs" ''
  set -e

  # Generates a CA, if one does not exist, in the current directory.
  function genCa() {
    csrjson=$1
    [ -n "$csrjson" ] || { echo "Usage: genCa CSRJSON" && return 1; }
    [ -f ca.pem ] && { echo "$(realpath ca.pem) exists, not replacing the CA" && return 0; }
    ${cfssl}/bin/cfssl gencert -loglevel 2 -initca "$csrjson" | ${cfssl}/bin/cfssljson -bare ca
  }

  # Generates a certificate signed by ca.pem from the current directory
  # (convention over configuration).
  function genCert() {
    profile=$1
    output=$2 # e.g. `apiserver/client` will result in `apiserver/client.pem` and `apiserver/client-key.pem`
    csrjson=$3

    { [ -n "$profile" ] && [ -n "$output" ] && [ -n "$csrjson" ]; } \
        || { echo "Usage: genCert PROFILE OUTPUT CSRJSON" && return 1; }

    ${cfssl}/bin/cfssl gencert \
        -loglevel 2 \
        -ca ca.pem \
        -ca-key ca-key.pem \
        -config ${caConfig} \
        -profile "$profile" \
        "$csrjson" \
        | ${cfssl}/bin/cfssljson -bare "$output"
  }


  out=./certs/generated

  ${pkgs.callPackage ./etcd.nix { }}
  ${pkgs.callPackage ./kubernetes.nix { }}
  ${pkgs.callPackage ./flannel.nix { }}
''
