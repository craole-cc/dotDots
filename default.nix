{
  lib,
  src,
  ...
}: let
  inherit (import ./Libraries {inherit lib src;}) lix;
  inherit (import ./API {inherit lix;}) hosts users;

  inherit (lix.getSystems {inherit hosts legacyPackages;}) per pkgsFor;
  # args = {inherit lix self;};
  # nixosConfigurations = lix.mkCore {
  #   inherit
  #     inputs
  #     hosts
  #     users
  #     args
  #     ;
  #   inherit (lib) nixosSystem;
  # };
  # devShells = per (system: let
  #   pkgs = pkgsFor system;
  # in {
  #   default = import ./Packages/cli/dots {
  #     inherit self pkgs lib hosts lix system;
  #   };
  # });
in {
  inherit
    # nixosConfigurations
    # devShells
    ;
}
