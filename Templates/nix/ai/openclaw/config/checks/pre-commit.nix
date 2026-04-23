{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in
  inputs.git-hooks.lib.${system}.run {
    src = inputs.self;
    hooks = {
      nil.enable = true;
      # statix.enable = true;
      treefmt = {
        enable = true;
        package = (inputs.treefmt.lib.evalModule pkgs ../treefmt.nix).config.build.wrapper;
      };
    };
  }
