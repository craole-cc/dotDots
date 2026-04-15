{
  lib ? {},
  inputs ? {},
}: let
  paths = {
    root = ./.;
    libraries = ./libraries;
    devShells = ./environment;
  };

  shell = {
    inherit paths;
    lib = import paths.libraries {
      lib =
        if inputs != {}
        then inputs.NixPackages.lib
        else if lib != {}
        then lib
        else (import <nixpkgs> {}).lib;
    };
    # packages =
    pkgs = shell.lib.packages.mkPkgs {inherit inputs;};
  };

  flake =
    shell
    // shell.lib.optionalAttrs (inputs != {}) {
      inherit inputs;
      inherit
        (import paths.devShells {
          inherit inputs;
          inherit (shell) lib;
        })
        devShells
        ;
    };
in
  if flake != {}
  then flake
  else shell
