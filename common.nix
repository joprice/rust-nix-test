let
  mozOverlay = import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz);
  pkgs = (
    import <nixpkgs>
      {
        overlays = [
          mozOverlay
          (
            self: super: {
              rustChannel = self.rustChannelOf {
                rustToolchain = ./rust-toolchain;
              };
              cargo = self.rustChannel.rust;
              rustc = self.rustChannel.rust;
            }
          )
        ];
      }
  ).pkgsCross.armv7l-hf-multiplatform;
  alsaLibStatic = (pkgs.alsaLib.overrideAttrs
    (o: {
      configureFlags = [
        "--enable-shared=no"
        "--enable-static=yes"
      ];
    }));
  crateOverrides = pkgs.defaultCrateOverrides // {
    alsa-sys = attrs: attrs // {
      nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [
        pkgs.buildPackages.pkg-config
      ];
      buildInputs = (attrs.buildInputs or [ ]) ++ [ alsaLibStatic ];
    };
    prost-build = attrs: attrs // {
      PROTOC = "${pkgs.buildPackages.protobuf}/bin/protoc";
    };
    client = attrs: attrs // {
      PROTOS_DIR = ./proto;
      buildInputs = [
        # this is needed to format the generated grpc code
        pkgs.buildPackages.rustfmt
        # TODO: add to all packages (expect proc macro and build scripts)?
        # pkgs.glibc.static
      ];
    };
  };
  cargo_nix = pkgs.callPackage
    ./Cargo.nix
    {
      release = false;
      # NOTE: cross building works with this disabled
      targetFeatures = [
        "crt-static"
      ];
      defaultCrateOverrides = crateOverrides;
    };
in
{
  pkgs = pkgs;
  build = cargo_nix.allWorkspaceMembers;
  shell = pkgs.mkShell {
    nativeBuildInputs = [ pkgs.buildPackages.rustChannel.rust ];
  };
}
