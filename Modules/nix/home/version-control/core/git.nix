{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkEnableOption mkOption;
  inherit
    (lix.types.combinators)
    attrsOf
    listOf
    nullOr
    submodule
    ;
  inherit (lix.types.primitives) anything str;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "git";
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {inherit context;};

      lfs.enable =
        mkEnableOption "Git Large File Storage (LFS)"
        // {
          default = true;
        };

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
            options.insteadOf = mkOption {
              type = listOf str;
              default = [];
              description = "URL prefixes to rewrite";
            };
          });
          default = {
            "https://github./" = {
              insteadOf = [
                "gh:"
                "github:"
              ];
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
        inherit (cfg) enable;
        lfs = {inherit (cfg.lfs) enable;};
        settings = {
          user = {
            name = cfg.user.name;
            email = cfg.user.email;
          };
          core.whitespace = cfg.settings.core.whitespace;
          init.defaultBranch = cfg.settings.init.defaultBranch;
          url = cfg.settings.url;
        };
        inherit (cfg) includes;
      };
    };
  }
