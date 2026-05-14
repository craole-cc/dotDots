{ lib }:
let
  inherit (lib.lists) elem head;

  defaultSystems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  getSystem =
    arg:
    if arg ? pkgs && arg.pkgs != null then
      arg.pkgs.stdenv.hostPlatform.system
    else if arg ? stdenv then
      arg.stdenv.hostPlatform.system
    else
      builtins.currentSystem or (throw "getSystem: pass pkgs or an attrset with pkgs");

  getSystemOrDefault =
    {
      pkgs ? null,
      systems ? defaultSystems,
    }:
    pkgs.stdenv.hostPlatform.system or (builtins.currentSystem or (head systems));

  defineSystems =
    {
      systems ? defaultSystems,
    }:
    systems;
  defineSystem =
    {
      system ? getSystemOrDefault { },
      systems ? defineSystems { },
    }:
    if elem system systems then system else throw "Unsupported system: ${system}";
in
{
  inherit
    defaultSystems
    defineSystem
    defineSystems
    getSystem
    getSystemOrDefault
    ;
}
