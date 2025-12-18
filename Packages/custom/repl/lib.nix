{
  lib,
  flakePath ? null,
  hostnamePath ? "/etc/hostname",
  registryPath ? "/etc/nix/registry.json",
}: let
  inherit (lib.attrsets) removeAttrs isAttrs;
  inherit (lib.strings) match;
  inherit (lib.lists) head elemAt length filter;
  inherit
    (builtins)
    pathExists
    readFile
    toString
    isPath
    currentSystem
    getFlake
    ;
  inherit (lib.json) fromFile;

  resolveFlakePath =
    if flakePath != null
    then
      if isPath flakePath
      then toString flakePath
      else flakePath
    else "/etc/nixos";

  selfFlake =
    if pathExists registryPath
    then filter (f: f.from.id == "self") (fromFile registryPath).flakes
    else [];

  flakePath' =
    if selfFlake != []
    then (head selfFlake).to.path
    else resolveFlakePath;

  flake =
    if pathExists flakePath'
    then getFlake flakePath'
    else null;

  hostname =
    if pathExists hostnamePath
    then let
      m = match "([a-zA-Z0-9\\-]+)\n" (readFile hostnamePath);
    in
      if m != null
      then head m
      else ""
    else "";

  findFirstPath = {
    index ? 0,
    names ? [],
    inputs ? null,
  }:
    if names == [] || index >= length names
    then throw "No possible inputs defined"
    else let
      name = elemAt names index;
    in
      if inputs != null && inputs ? "${name}"
      then inputs."${name}".outPath
      else
        findFirstPath {
          inherit (inputs) names;
          index = index + 1;
        };

  pkgsFromInputsPath = let
    path = findFirstPath {
      inherit (flake) inputs;
      names = [
        "nixpkgs"
        "nixPackages"
        "nixosCore"
        "nixpkgsUnstable"
        "nixpkgsStable"
        "nixpkgs-unstable"
        "nixpkgs-stable"
        "nixosPackages"
        "nixosUnstable"
        "nixosStable"
      ];
    };
  in
    if path != ""
    then import path {}
    else null;

  nixpkgs = flake.pkgs.${currentSystem}.nixpkgs or pkgsFromInputsPath;

  nixpkgsOutput = removeAttrs (nixpkgs // (nixpkgs.lib or {})) [
    "options"
    "config"
  ];
in
  {inherit flake;}
  // builtins
  // (
    if
      isAttrs flake
      && flake ? nixosConfigurations
      && flake.nixosConfigurations ? "${hostname}"
    then flake.nixosConfigurations."${hostname}"
    else {}
  )
  // nixpkgsOutput
  // {getFlake = path: getFlake (toString path);}
