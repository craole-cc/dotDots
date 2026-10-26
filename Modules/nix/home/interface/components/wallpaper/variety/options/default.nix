{
  lix,
  context,
  wallpaper,
  paths,
  pkgs,
  ...
} @ args: let
  inherit (context) mod;
  inherit (lix.attrsets.aggregation) recursiveMergeAll;
  inherit (lix.options.construction) literalExpression mkOption mkEnable;
  inherit (lix.types.combinators) attrsOf enum nullOr oneOf;
  inherit (lix.types.primitives) bool float package int str;
in
  {
    enable = mkEnable {
      inherit context;
      condition = wallpaper.cfg.engine == mod;
    };

    package = mkOption {
      type = package;
      default = pkgs.variety;
      defaultText = literalExpression "pkgs.${mod}";
    };

    profile = {
      name = mkOption {
        type = nullOr str;
        default = null;
        example = "declarative";
        description = ''
          Variety profile. A bare name maps to
          $XDG_CONFIG_HOME/variety-profiles/<name>, an absolute path is used as is,
          and null means the default ~/.config/variety. Unless null, the
          installed `variety` binary is wrapped so that every invocation
          (including `variety --next` from keybinds) targets this profile.
        '';
      };

      path = mkOption {
        type = str;
        readOnly = true;
        description = "Resolved configuration folder of the profile.";
        default = paths.variety.profiles.active;
      };
    };

    seed.mode = mkOption {
      type = enum ["overwrite" "ifMissing"];
      default = "overwrite";
      description = ''
        overwrite: every switch rewrites variety.conf, so Nix is the source
        of truth (changes made in the Preferences dialog are lost).
        ifMissing: only write variety.conf when it does not exist yet.
        Variety rewrites the file itself when preferences change or on
        exit, so quit a running instance before switching.
      '';
    };

    extraSettings = mkOption {
      type = attrsOf (oneOf [bool int float str]);
      default = {};
      example = {
        min_size_enabled = true;
        min_size = 80;
      };
      description = ''
        Any other top-level variety.conf key. These win over everything
        else, including settings generated from the declared options.
      '';
    };
  }
  // recursiveMergeAll (
    map (file: import file args) [
      ./scripts.nix
      ./clock.nix
      ./folders.nix
      ./filters.nix
      ./sources.nix
      ./constraints.nix
      ./features.nix
      ./quotes.nix
      ./slideshow.nix
    ]
  )
