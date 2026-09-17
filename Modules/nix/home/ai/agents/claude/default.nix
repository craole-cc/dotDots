{
  config,
  inputs,
  system,
  lix,
  user,
  lib,
  pkgs,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "claude";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkConfig mkContext mkIf mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.combinators) attrsOf listOf nullOr;
  inherit (lix.types.primitives) anything package path str;
  inherit (lib.hm.dag) entryAfter;
  inherit (lib.strings) escapeShellArg;
  sh = with pkgs; {
    rm = "${coreutils}/bin/rm";
    mkdir = "${coreutils}/bin/mkdir";
    install = "${coreutils}/bin/install";
    dirname = "${coreutils}/bin/dirname";
  };
  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  selectedApplications = let
    ai = user.applications.ai or {};
  in
    map (key: ai.${key}) (
      filter (key: ai ? ${key})
      ["primary" "secondary" "tertiary"]
    )
    ++ (user.applications.allowed or []);

  settingsSource =
    if cfg.settingsFile != null
    then cfg.settingsFile
    else pkgs.writeText "claude-code-settings.json" (builtins.toJSON cfg.settings);
  instructionsSource =
    if cfg.instructionsFile != null
    then cfg.instructionsFile
    else pkgs.writeText "claude-code-instructions.md" cfg.instructions;
in
  mkConfig {
    inherit context;

    # Claude Desktop remains an application role. This module configures the
    # distinct terminal agent, Claude Code, for one Home Manager user.
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn ["claude-code" "claude"] selectedApplications;
      };

      package = mkOption {
        type = package;
        default = inputs.llm-agents.packages.${system}."claude-code";
        description = "Claude Code package to expose in this user's profile.";
      };

      extraPackages = mkOption {
        type = listOf package;
        default = [];
        description = "Tools Claude Code should have available in this user's profile.";
      };

      # This maps to ~/.claude/settings.json. It covers permissions, hooks,
      # model/provider behaviour, and the native Claude Code env block.
      settings = mkOption {
        type = attrsOf anything;
        default = {};
        description = "Public Claude Code settings rendered as JSON.";
      };

      settingsFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Prewritten public settings.json; takes precedence over settings.";
      };

      # This maps to ~/.claude/CLAUDE.md, which Claude Code loads for every
      # project. Per-project instructions remain owned by each project.
      instructions = mkOption {
        type = str;
        default = "";
        description = "User-wide Claude Code instructions rendered to ~/.claude/CLAUDE.md.";
      };

      instructionsFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Prewritten user-wide CLAUDE.md; takes precedence over instructions.";
      };

      # Only non-secret values belong here. Authentication stays in Claude
      # Code's credential store or an externally managed secret source.
      environment = mkOption {
        type = attrsOf str;
        default = {};
        description = "Non-secret environment variables for the user's Claude Code sessions.";
      };
    };

    outputs = mkMerge [
      {
        home = {
          packages = [cfg.package] ++ cfg.extraPackages;
          sessionVariables = cfg.environment;
        };
      }
      (mkIf (cfg.settingsFile != null || cfg.settings != {}) {
        # Claude Code may update user settings. Install a real file rather than
        # a Home Manager symlink so its writes never target the Nix store.
        home.activation.materializeClaudeCodeSettings = entryAfter ["linkGeneration"] ''
          target="$HOME/.claude/settings.json"
          if [ -L "$target" ]; then
            ${sh.rm} -f "$target"
          fi
          ${sh.mkdir} -p "$( ${sh.dirname} "$target")"
          ${sh.install} -m 0600 ${escapeShellArg settingsSource} "$target"
        '';
      })
      (mkIf (cfg.instructionsFile != null || cfg.instructions != "") {
        home.activation.materializeClaudeCodeInstructions = entryAfter ["linkGeneration"] ''
          target="$HOME/.claude/CLAUDE.md"
          if [ -L "$target" ]; then
            ${sh.rm} -f "$target"
          fi
          ${sh.mkdir} -p "$( ${sh.dirname} "$target")"
          ${sh.install} -m 0644 ${escapeShellArg instructionsSource} "$target"
        '';
      })
    ];
  }
