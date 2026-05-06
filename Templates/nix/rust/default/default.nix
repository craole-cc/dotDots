{
  description ? "Rust development environment with AI Tools",
  lib ? null,
  inputs ? null,
  system ? null,
}: let
  paths = let
    flake = ./.;
    nix = flake + "/.nix";
    mkCfg = path: nix + "/${path}";
  in {
    inherit flake nix;
    scripts.default = flake + "/.bin";
    templates.default = mkCfg "templates";
    downloads = flake + "/downloads";
    environment = mkCfg "environment";
    libraries = mkCfg "libraries";
    modules = mkCfg "modules";
    repl = mkCfg "repl.nix";
  };

  libraries = import paths.libraries {
    inherit paths;
    lib =
      if lib != null
      then lib
      else if inputs != null && inputs ? NixPackages
      then inputs.NixPackages.lib
      else (import <nixpkgs> {}).lib;
  };

  packages = libraries.packages.mkPkgs {inherit inputs system;};
  repl = import paths.repl {inherit libraries packages;};
in {
  inherit description paths repl;
  pkgs = packages;
  lib = libraries;
}
