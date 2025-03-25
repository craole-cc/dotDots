{lib, ...}: let
  inherit (lib.types) attrsOf path submodule;
  inherit (lib.options) mkOption;
in {
  options.hosts = mkOption {
    type = attrsOf (submodule {
      options = {
        paths.local = mkOption {
          type = path;
          description = "Local dotfiles path for this host";
        };
      };
    });
    description = "Host-specific configurations";
  };
}
