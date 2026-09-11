{
  config,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lib.hm.dag) entryAfter;
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.options.construction) mkEnable mkEnableOption mkOption;
  inherit (lix.strings.construction) concatMapStringsSep;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit
    (lix.types.combinators)
    attrsOf
    listOf
    nullOr
    submodule
    ;
  inherit (lix.types.primitives) anything bool str;
  inherit (pkgs) git;

  context = mkContext {
    inherit config;
    dom = "version-control";
    sub = "core";
    mod = "git";
  };
  inherit (context) cfg;

  userGitSettings = user.git.settings or {};

  legacyOwnedKeys = [
    "user.name"
    "user.email"
    "alias.project-summary"
    "push.autoSetupRemote"
    "credential.helper"
    "credential.https://github.com.helper"
    "credential.https://gist.github.com.helper"
  ];

  unsetLegacyOwnedKeys = concatMapStringsSep "\n" (key: ''
    $DRY_RUN_CMD ${git}/bin/git config --file "$legacy" --unset-all ${escapeShellArg key} 2>/dev/null || true
  '') legacyOwnedKeys;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = user.applications.utilities.git.enable or false;
      };

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
        alias = mkOption {
          type = attrsOf str;
          default = userGitSettings.alias or {};
          description = "Git aliases";
        };
        core.whitespace = mkOption {
          type = str;
          default = userGitSettings.core.whitespace or "trailing-space,space-before-tab";
          description = "Git core.whitespace rule setting";
        };
        init.defaultBranch = mkOption {
          type = str;
          default = userGitSettings.init.defaultBranch or "main";
          description = "Default branch name for new repositories";
        };
        push.autoSetupRemote = mkOption {
          type = bool;
          default = userGitSettings.push.autoSetupRemote or false;
          description = "Automatically set the upstream remote on first push";
        };
        url = mkOption {
          type = attrsOf (submodule {
            options.insteadOf = mkOption {
              type = listOf str;
              default = [];
              description = "URL prefixes to rewrite";
            };
          });
          default = userGitSettings.url or {
            "https://github.com/" = {
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
          inherit (cfg.settings) alias url;
          core.whitespace = cfg.settings.core.whitespace;
          init.defaultBranch = cfg.settings.init.defaultBranch;
          push.autoSetupRemote = cfg.settings.push.autoSetupRemote;
        };
        inherit (cfg) includes;
      };

      # Home Manager owns ~/.config/git/config. Remove only legacy ~/.gitconfig
      # keys that are now represented declaratively, preserving unrelated data.
      home.activation.removeLegacyGitConfig = entryAfter ["writeBoundary"] ''
        legacy="$HOME/.gitconfig"

        if [ -f "$legacy" ]; then
          ${unsetLegacyOwnedKeys}

          remaining="$(${git}/bin/git config --file "$legacy" --list 2>/dev/null || true)"
          if [ -z "$remaining" ]; then
            $DRY_RUN_CMD rm -f "$legacy"
          fi
        fi
      '';
    };
  }
