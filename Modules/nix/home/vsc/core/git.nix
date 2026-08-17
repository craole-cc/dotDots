{
  config,
  lix,
  top,
  user,
  ...
}: let
  dom = "version-control";
  sub = "core";
  mod = "git";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.types.combinators) attrsOf listOf nullOr submodule;
  inherit (lix.types.primitives) anything str;
in
  mkConfig {
    inherit config top dom sub mod;

    options = {
      enable =
        mkEnableOption mod
        // {default = true;};

      lfs.enable =
        mkEnableOption "Git Large File Storage (LFS)"
        // {default = true;};

      user = {
        name = mkOption {
          type = nullOr str;
          default = user.git.name or null;
          description = "Git user name";
        };
        email = mkOption {
          type = nullOr str;
          default = user.git.email or null;
          description = "Git user email address";
        };
      };

      settings = {
        core.whitespace = mkOption {
          type = str;
          default = "trailing-space,space-before-tab";
          description = "Git core.whitespace rule setting";
        };
        init.defaultBranch = mkOption {
          type = str;
          default = "main";
          description = "Default branch name for new repositories";
        };
        url = mkOption {
          type = attrsOf (submodule {
            options = {
              insteadOf = mkOption {
                type = listOf str;
                default = [];
                description = "URL prefixes to rewrite";
              };
            };
          });
          default = {
            "https://github./" = {
              insteadOf = ["gh:" "github:"];
            };
          };
          description = "Git URL rewrite mappings";
        };
      };

      includes = mkOption {
        type = listOf anything;
        default = [];
        description = "Additional Git include directives";
      };
    };

    outputs = {
      programs.git = {
        enable = cfg.enable;
        lfs.enable = cfg.lfs.enable;
        settings = {
          user = {
            name = cfg.user.name;
            email = cfg.user.email;
          };
          core.whitespace = cfg.settings.core.whitespace;
          init.defaultBranch = cfg.settings.init.defaultBranch;
          url = cfg.settings.url;
        };
        includes = cfg.includes;
      };
    };
  }
