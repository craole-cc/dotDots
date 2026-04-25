{
  description ? "Rust development environment with AI Tools",
  paths ? {
    libraries = ./libraries;
    environment = ./environment;
    templates = ./templates;
    modules = ./modules;
    config = ./config;
    downloads = ./downloads;
  },
  lib ? null,
  inputs ? null,
  system ? null,
  config ? null,
}: let
  inherit (builtins) hasAttr head isAttrs pathExists tail;
  findFirst = names: set:
    if names == []
    then null
    else let
      name = head names;
    in
      if hasAttr name set
      then name
      else findFirst (tail names) set;

  nixpkgs = let
    name =
      if isAttrs inputs
      then
        findFirst [
          "NixPkgsUnstable"
          "NixPackagesUnstable"
          "nixpkgs-unstable"
          "NixPackages"
          "NixPkgs"
          "nixpkgs-stable"
          "nixpkgs"
        ]
        inputs
      else null;
    cfg = {
      config =
        if config != null
        then config
        else {allowUnfree = true;};
      system =
        if system != null
        then system
        else builtins.currentSystem or "x86_64-linux";
    };
  in
    if name != null
    then import inputs.${name} cfg
    else import <nixpkgs> cfg;

  libraries = let
    lib' =
      if isAttrs lib
      then lib
      else nixpkgs.lib;
  in
    if paths ? libraries && pathExists paths.libraries
    then import paths.libraries {lib = lib';}
    else lib';
  inherit (libraries.packages) mkPkgs getSystemOrDefault;

  packages = mkPkgs {inherit inputs;};

  templates =
    libraries.optionalAttrs
    (paths ? templates && pathExists paths.templates)
    import
    paths.templates {
      lib = libraries;
      pkgs = packages;
    };
in {
  inherit description templates;
  paths = {src = ./.;} // paths;
  lib = libraries;
  pkgs = packages;
  system = getSystemOrDefault {pkgs = packages;};
}
