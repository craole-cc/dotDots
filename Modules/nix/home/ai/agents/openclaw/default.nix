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
  mod = "openclaw";

  inherit (lib.hm.dag) entryAfter;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.lists.transformation) filter;
  inherit (lix.modules.construction) mkConfig mkContext mkIf mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.construction) toJSON;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (lix.types.combinators) attrsOf listOf nullOr;
  inherit (lix.types.primitives) anything bool package path str;
  inherit (pkgs) writeText;
  bin = with pkgs; {
    rm = "${coreutils}/bin/rm";
    mkdir = "${coreutils}/bin/mkdir";
    install = "${coreutils}/bin/install";
    dirname = "${coreutils}/bin/dirname";
    mod = "${cfg.package}/bin/${mod}";
  };

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn [mod] (let
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
        default = inputs.llm-agents.packages.${system}.${mod};
        description = "OpenClaw package to expose in this user's profile.";
      };

      extraPackages = mkOption {
        type = listOf package;
        default = [];
        description = "Tools OpenClaw agents should have available in this user's profile.";
      };

      # OpenClaw accepts JSON5; strict JSON generated from Nix is valid JSON5.
      # Keep credentials as ${VAR} references or SecretRef values, never as
      # literal values in this Nix option.
      settings = mkOption {
        type = attrsOf anything;
        default = {};
        description = "Public OpenClaw configuration rendered as ~/.openclaw/openclaw.json.";
      };

      configFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Prewritten public OpenClaw JSON5 configuration; takes precedence over settings.";
      };

      # OpenClaw uses process environment for endpoint overrides and may resolve
      # ${VAR} references in its config. This must contain only non-secrets.
      environment = mkOption {
        type = attrsOf str;
        default = {};
        description = "Non-secret environment variables for the user's OpenClaw sessions.";
      };

      gateway = {
        enable = mkOption {
          type = bool;
          default = false;
          description = "Run the OpenClaw Gateway as a per-user systemd service.";
        };

        service = mkOption {
          type = anything;
          default = {};
          description = "Additional systemd.user.services.openclaw options.";
        };
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
        inherit (cfg) configFile settings;
        source =
          if configFile != null
          then configFile
          else writeText "openclaw.json" (toJSON settings);
        target = "$HOME/.openclaw/openclaw.json";
      in
        mkIf (configFile != null || settings != {}) {
          # OpenClaw requires its active config path to be a regular file; a
          # Home Manager symlink would let OpenClaw replace the store target.
          home = {
            activation.materializeOpenClawConfig = entryAfter ["linkGeneration"] ''
              if [ -L "${target}" ]; then
                ${bin.rm} -f "${target}"
              fi
              ${bin.mkdir} -p "$( ${bin.dirname} "${target}")"
              ${bin.install} -m 0600 ${escapeShellArg source} "${target}"
            '';
            sessionVariables.OPENCLAW_CONFIG_READONLY = "1";
          };
        })
      (mkIf cfg.gateway.enable {
        systemd.user.services.openclaw =
          recursiveUpdate {
            Unit = {
              Description = "OpenClaw Gateway";
              After = ["network-online.target"];
            };
            Service = {
              ExecStart = "${bin.mod} gateway run";
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install.WantedBy = ["default.target"];
          }
          cfg.gateway.service;
      })
    ];
  }
