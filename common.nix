let
  pkgs = (import
    (builtins.fetchTarball {
      name = "unstable";
      url = "https://github.com/nixos/nixpkgs/archive/49715830f95f817861405c44d27312d0aa881f65.tar.gz";
      sha256 = "0ipm0y9fnkzpq526dnih7srxm2d6gpi4zzn95r0pa5qlyqdfrzff";
    })
    { }).pkgsCross.armv7l-hf-multiplatform.pkgsStatic;
  #pkgs = (import <nixpkgs> { }).pkgsCross.armv7l-hf-multiplatform.pkgsStatic;
  crateOverrides = pkgs.defaultCrateOverrides // {
    alsa-sys = attrs: attrs // {
      nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [
        pkgs.buildPackages.pkg-config
      ];
      buildInputs = (attrs.buildInputs or [ ]) ++ [ pkgs.alsaLib ];
    };
    prost-build = attrs: attrs // {
      PROTOC = "${pkgs.buildPackages.protobuf}/bin/protoc";
    };
    client = attrs: attrs // {
      PROTOS_DIR = ./proto;
      nativeBuildInputs = [
        # this is needed to format the generated grpc code
        pkgs.buildPackages.rustfmt
      ];
    };
  };
  cargo_nix = pkgs.callPackage
    ./Cargo.nix
    {
      release = false;
      defaultCrateOverrides = crateOverrides;
    };
in
{
  pkgs = pkgs;
  build = cargo_nix.allWorkspaceMembers;
  shell = pkgs.mkShell {
    nativeBuildInputs = [ pkgs.buildPackages.rustc ];
  };
}
