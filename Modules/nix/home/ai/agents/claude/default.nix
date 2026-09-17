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
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.strings.construction) toJSON;
  inherit (pkgs) writeText;
  sh = with pkgs; {
    rm = "${coreutils}/bin/rm";
    mkdir = "${coreutils}/bin/mkdir";
    install = "${coreutils}/bin/install";
    dirname = "${coreutils}/bin/dirname";
  };

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    # Claude Desktop remains an application role. This module configures the
    # distinct terminal agent, Claude Code, for one Home Manager user.
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn ["claude-code" "claude"] (let
          domain = user.applications.${dom} or {};
        in
          (user.applications.allowed or [])
          ++ map (module: domain.${module}) (
            filter (module: domain ? ${module})
            ["primary" "secondary" "tertiary"]
          ));
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
      (let
        inherit (cfg) settingsFile settings;
        source =
          if settingsFile != null
          then settingsFile
          else writeText "claude-code-settings.json" (toJSON settings);
        target = "$HOME/.claude/settings.json";
      in
        mkIf (settingsFile != null || settings != {}) {
          home.activation.materializeClaudeCodeSettings = entryAfter ["linkGeneration"] ''
            if [ -L "${target}" ]; then
              ${sh.rm} -f "${target}"
            fi
            ${sh.mkdir} -p "$( ${sh.dirname} "${target}")"
            ${sh.install} -m 0600 ${escapeShellArg source} "$target"
          '';
        })
      (let
        inherit (cfg) instructionsFile instructions;
        source =
          if instructionsFile != null
          then instructionsFile
          else writeText "claude-code-instructions.md" instructions;
        target = "$HOME/.claude/CLAUDE.md";
      in
        mkIf (instructionsFile != null || instructions != "") {
          home.activation.materializeClaudeCodeInstructions = entryAfter ["linkGeneration"] ''
            if [ -L "${target}" ]; then
              ${sh.rm} -f "${target}"
            fi
            ${sh.mkdir} -p "$( ${sh.dirname} "${target}")"
            ${sh.install} -m 0644 ${escapeShellArg source} "${target}"
          '';
        })
    ];
  }
