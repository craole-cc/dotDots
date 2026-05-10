{
  description ? "Rust development environment with AI Tools",
  inputs ? null,
  system ? null,
}: let
  paths = let
    flake = ./.;
    nix = flake + "/.nix";
    mkCfg = path: nix + "/${path}";
  in {
    inherit flake nix;
    # downloads = flake + "/downloads";
    # environment = mkCfg "environment";
    libraries = mkCfg "libraries";
    # modules = mkCfg "modules";
    scripts.default = flake + "/.bin";
    # templates.default = mkCfg "templates";
  };

  lib = import paths.libraries {
    inherit paths;
    lib =
      if inputs != null && inputs ? NixPackages
      then inputs.NixPackages.lib
      else (import <nixpkgs> {}).lib;
  };

  pkgs = lib.packages.mkPkgs {inherit inputs system;};
in {
  inherit description lib paths pkgs;
  repl = import paths.nix {inherit lib pkgs;};
}
