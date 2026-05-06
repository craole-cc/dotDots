{
  description ? "Rust development environment with AI Tools",
  lib ? null,
  inputs ? null,
  system ? null,
  paths ? let
    src = ../.;
    nix = src + "/.nix";
    scr = src + "/.bin";
    mkCfg = path: nix + "/${path}";
  in {
    inherit nix src;
    templates.config = mkCfg "templates";
    libraries = mkCfg "libraries";
    repl = mkCfg "repl.nix";
    scripts.src = scr;
  },
}: let
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
  repl = import paths.repl {
    inherit libraries packages;
  };
in {
  inherit description paths repl;
  pkgs = packages;
  lib = libraries;
}
