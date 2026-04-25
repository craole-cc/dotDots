{lib}: let
  inherit (lib.lists) elem head;

  defaultSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  getSystem = {pkgs ? null}:
    if pkgs ? stdenv.hostPlatform.system
    then pkgs.stdenv.hostPlatform.system
    else builtins.currentSystem or
        throw "getSystem: pass `pkgs` or run outside --pure-eval";

  getSystemOrDefault = {
    pkgs ? null,
    systems ? defaultSystems,
  }:
    if pkgs ? stdenv.hostPlatform.system
    then pkgs.stdenv.hostPlatform.system
    else builtins.currentSystem or (head systems);

  defineSystems = {systems ? defaultSystems}: systems;
  defineSystem = {
    system ? getSystemOrDefault {},
    systems ? defineSystems {},
  }:
    if elem system systems
    then system
    else throw "Unsupported system: ${system}";
in {
  inherit
    defaultSystems
    defineSystem
    defineSystems
    getSystem
    getSystemOrDefault
    ;
}
