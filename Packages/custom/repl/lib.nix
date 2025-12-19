{
  lib ? import <nixpkgs/lib>,
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
    fromJSON
    tryEval
    ;

  resolveFlakePath =
    if flakePath != null
    then
      if isPath flakePath
      then toString flakePath
      else flakePath
    else "/etc/nixos";

  readRegistrySafe =
    if pathExists registryPath
    then let
      content = readFile registryPath;
      parsed = tryEval (fromJSON content);
    in
      if parsed.success
      then parsed.value
      else {}
    else {};

  selfFlake = filter (f: f.from.id == "self") (readRegistrySafe.flakes or []);

  flakePath' =
    if selfFlake != []
    then (head selfFlake).to.path
    else resolveFlakePath;

  flake =
    if pathExists flakePath'
    then let
      result = tryEval (getFlake flakePath');
    in
      if result.success
      then result.value
      else null
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
    inputs ? {},
  }:
    if names == [] || index >= length names
    then null
    else let
      name = elemAt names index;
    in
      if inputs ? "${name}" && inputs."${name}" ? outPath
      then inputs."${name}".outPath
      else
        findFirstPath {
          inherit names;
          inputs = inputs;
          index = index + 1;
        };

  pkgsFromInputsPath =
    if flake != null && flake ? inputs
    then let
      path = findFirstPath {
        inputs = flake.inputs;
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
      if path != null
      then import path {}
      else null
    else null;

  nixpkgs =
    if flake != null && flake ? pkgs && flake.pkgs ? ${currentSystem} && flake.pkgs.${currentSystem} ? nixpkgs
    then flake.pkgs.${currentSystem}.nixpkgs
    else pkgsFromInputsPath;

  nixpkgsOutput =
    if nixpkgs != null
    then
      removeAttrs nixpkgs [
        "options"
        "config"
        "lib" # Don't include lib in nixpkgsOutput
      ]
    else {};

  # Add lib from nixpkgs if available
  libOutput =
    if nixpkgs != null && nixpkgs ? lib
    then nixpkgs.lib
    else lib;

  hasConfiguration =
    isAttrs flake
    && flake ? nixosConfigurations
    && hostname != ""
    && flake.nixosConfigurations ? "${hostname}";

  configuration =
    if hasConfiguration
    then flake.nixosConfigurations."${hostname}"
    else {};
in
  {
    inherit flake hostname;
    pkgs = nixpkgsOutput;
    lib = libOutput;
    config = configuration;

    safeGetFlake = path: let
      result = tryEval (getFlake (toString path));
    in
      if result.success
      then result.value
      else null;
  }
  // nixpkgsOutput
