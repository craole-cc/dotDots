{
  context,
  defined,
  lix,
  user,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkEnable mkTrue mkOption;
  inherit (lix.schema.packages) resolve;
  inherit (lix.types.combinators) attrsOf listOf nullOr submodule;
  inherit (lix.types.primitives) anything bool str strMatching;
in {
  enable = mkEnable {
    inherit context;
    condition = isIn "git" ((resolve {record = user;}).utilities or []);
  };
  lfs.enable = mkTrue "Git Large File Storage (LFS)";

  identities = mkOption {
    type = listOf (submodule {
      options = {
        id = mkOption {
          description = "Optional identifier for this Git identity";
          default = null;
          type = nullOr str;
        };
        name = mkOption {
          description = "Git author name for this repository identity; when set, overrides settings.user.name";
          default = null;
          type = nullOr str;
        };
        email = mkOption {
          description = "Git author email for this repository identity; when set, overrides settings.user.email";
          default = null;
          type = nullOr str;
        };
        root = mkOption {
          description = "Required non-empty repository path: absolute, ~/ prefixed, or relative to the home directory; trailing slashes are normalised";
          type = strMatching ".+";
        };
        settings = mkOption {
          description = "Git settings applied to repositories matched by this identity";
          default = {};
          type = attrsOf anything;
        };
        license = {
          author = mkOption {
            description = "Copyright author for this repository identity";
            default = null;
            type = nullOr str;
          };
          default = mkOption {
            description = "Default licence identifier for this repository identity";
            default = null;
            type = nullOr str;
          };
        };
      };
    });
    default = defined.identities or [];
    description = "Git identities selected by repository root";
  };

  settings = let
    set = defined.settings or {};
  in {
    alias = mkOption {
      type = attrsOf str;
      default = set.alias or {};
      description = "Git aliases";
    };

    core = {
      whitespace = mkOption {
        type = str;
        default = set.core.whitespace or "trailing-space,space-before-tab";
        description = "Git core.whitespace rule setting";
      };
    };

    init = {
      defaultBranch = mkOption {
        type = str;
        default = set.init.defaultBranch or "main";
        description = "Default branch name for new repositories";
      };
    };

    push = {
      autoSetupRemote = mkOption {
        type = bool;
        default = set.push.autoSetupRemote or false;
        description = "Automatically set the upstream remote on first push";
      };
    };

    url = mkOption {
      type = attrsOf (submodule {
        options.insteadOf = mkOption {
          type = listOf str;
          default = [];
          description = "URL prefixes to rewrite";
        };
      });
      default =
        set.url or {
          "https://github.com/" = {
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
}
