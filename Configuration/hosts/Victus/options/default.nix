{
  systemName,
  configName,
  config,
  lib,
  _lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) attrsOf submodule;
  userAttrs = import ./users.nix {inherit lix lib;};
  policyAttrs = import ./policies.nix {inherit lix lib;};
  users = userAttrs.allUsers;
  policies = policyAttrs.allPolicies;
  test = mkOption {default = {};};
  hosts = mkOption {
    description = "All host configurations";
    default = {};
    type = attrsOf (
      submodule (
        {name, ...}: let
          inherit systemName configName config _lib lib pkgs name;
          _cfg = config.${configName};
        in {
          options = {
            enable = mkEnableOption name;
            inherit
              (import ./hardware.nix {inherit _cfg name _lib lib;})
              id
              stateVersion
              functionalities
              modules
              devices
              specs
              ;
            inherit (userAttrs) people users;
            access = import ./access.nix {inherit lib;};
            interface = import ./interface.nix {inherit args;};
            localization = import ./localization.nix {inherit args;};
            packages = import ./packages.nix {inherit args;};
            paths = import ./paths.nix {inherit args;};
          };
        }
      )
    );
  };
in {
  imports = [
    (import ./api {inherit systemName configName config lib _lib pkgs;})
  ];
  options.${configName} = {inherit hosts users policies test;};
}
