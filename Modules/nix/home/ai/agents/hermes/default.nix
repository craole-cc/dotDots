{
  config,
  inputs,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "hermes-agent";

  inherit (lix.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (lix.lists.aggregation) foldl';
  inherit (lix.lists.predicates) isIn;
  inherit (lix.schema.packages) selectedPackages;
  inherit (lix.modules.construction) mkConfig mkContext mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) anything;

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;

  # Reuse the renderers from the same flake input that supplies the package.
  common = import "${inputs.hermes-agent.outPath}/nix/moduleCommon.nix" {inherit lib;};
  bots = import ./bots {inherit cfg common config lib lix pkgs;};
  parts = [
    (import ./profiles {inherit bots cfg common config lib lix pkgs;})
    bots
    (import ./gateway {inherit cfg config lix pkgs;})
    (import ./swarm {inherit cfg config lix;})
  ];
  collect = field: mergeSafe (map (part: part.${field} or {}) parts);
  settings = foldl' recursiveUpdate {} (map (part: part.settings or {}) parts);
in
  mkConfig {
    inherit context;

    options = mergeSafe (collect "options") {
      enable = mkEnable {
        inherit context;
        condition =
          isIn ["hermes" "hermes-agent" "hermes-desktop"]
          (selectedPackages user);
      };

      # These are forwarded without narrowing the upstream Hermes interface.
      # `services` accepts settings, environmentFiles, mcpServers, backend,
      # documents, plugins, restart policy, and every future option under
      # services.hermes-agent.  Keep secrets in environmentFiles, not settings.
      services = mkOption {
        type = anything;
        default = {
          gateway.enable = true;
          extraDependencyGroups = ["messaging"];
        };
      };

      # This is the programs.hermes-agent shape: package and desktop options
      # may be overridden independently of the user service.
      programs = mkOption {
        type = anything;
        default.desktop.enable = true;
      };
    };

    outputs = mkMerge [
      {
        services.${mod} = recursiveUpdate cfg.services {
          enable = true;
          inherit settings;
        };
        programs.${mod} = cfg.programs // {enable = true;};
      }
      (mkMerge (map (part: part.outputs or {}) parts))
    ];
  }
