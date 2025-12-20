{src}: let
  inherit (import (src + "/Libraries") {inherit src;}) lix;
  api = import (src + "/API") {inherit lix;};
  inherit (api) hosts;
  inherit (lix) lib;

  lic = lix.configuration.resolution;
  inherit (lix.configuration.predicates) isSystemDefaultUser;

  flake = lic.flake {path = src;};
  nixosConfigurations = flake.nixosConfigurations or {};

  systems = lic.systems {inherit hosts;};
  inherit (systems) pkgs system;

  host = lic.host {inherit nixosConfigurations system;};
in {
  inherit lix api lib flake nixosConfigurations pkgs system host isSystemDefaultUser;
}
