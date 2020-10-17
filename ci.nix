{ pkgs ? import <nixpkgs> { } }:
let default = (import ./default.nix).shell; in
pkgs.mkShell
{
  buildInputs = default.buildInputs;
  GIT_SSL_CAINFO = /etc/ssl/certs/ca-certificates.crt;
  SSL_CERT_FILE = /etc/ssl/certs/ca-certificates.crt;
}
