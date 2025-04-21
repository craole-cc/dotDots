{
  lib,
  flakePath ? null,
  hostnamePath ? "/etc/hostname",
  registryPath ? "/etc/nix/registry.json",
}: let
  inherit (lib.attrsets) removeAttrs isAttrs;
  inherit (lib.strings) match;
  inherit
    (lib.lists)
    head
    elemAt
    length
    filter
    ;
  inherit
    (builtins)
    pathExists
    readFile
    toString
    isPath
    currentSystem
    getFlake
    ;

  # Robust path resolution
  resolveFlakePath =
    if flakePath != null
    then
      if isPath flakePath
      then toString flakePath
      else flakePath
    else "/etc/nixos";

  # Fallback registry-based path detection
  selfFlake =
    if pathExists registryPath
    then filter (f: f.from.id == "self") (lib.json.fromFile registryPath).flakes
    else [];

  flakePath' =
    if selfFlake != []
    then (head selfFlake).to.path
    else resolveFlakePath;

  # Ensure flake is a valid path or empty string
  # flake = if pathExists flakePath' then flakePath' else "";
  flake =
    if pathExists flakePath'
    then builtins.getFlake flakePath'
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
  # {
  #   inherit hostname nixpkgsOutput;
  #   # Ensure flake is always a string
  #   flake = if flake == "" then "/" else flake;
  #   getFlake = path: lib.evalModules { modules = [ (toString path) ]; };
  # }
  {
    inherit flake;
  }
  // builtins
  // (
    if isAttrs flake && flake ? nixosConfigurations && flake.nixosConfigurations ? "${hostname}"
    then flake.nixosConfigurations."${hostname}"
    else {}
  )
  // nixpkgsOutput
  // {
    getFlake = path: getFlake (toString path);
  }
