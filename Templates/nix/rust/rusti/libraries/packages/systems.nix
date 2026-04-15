{lib}: let
  inherit (lib.lists) elem head;

  supportedSystems = {
    systems ? [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ],
  }:
    systems;

  currentSystem =
    if builtins ? currentSystem
    then builtins.currentSystem
    else head (supportedSystems {});

  defineSystem = {
    system ? currentSystem,
    systems ? supportedSystems {},
  }:
    if elem system systems
    then system
    else throw "Unsupported system: ${system}";

  getSystem = pkgs: pkgs.stdenv.hostPlatform.system;
in {
  inherit
    defineSystem
    currentSystem
    supportedSystems
    getSystem
    ;
}
