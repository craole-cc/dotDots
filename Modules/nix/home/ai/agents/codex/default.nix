{
  config,
  inputs,
  lix,
  pkgs,
  user,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "codex";

  inherit (lix.lists.predicates) isIn;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config dom sub mod;
  };

  ai = user.applications.ai or {};
  selectedApplications =
    [
      (ai.primary or null)
      (ai.secondary or null)
      (ai.tertiary or null)
    ]
    ++ (user.applications.allowed or []);

  codex = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
in
  mkConfig {
    inherit context;

    # Codex authentication and profiles are per-user state under ~/.codex.
    # Install the client declaratively, but leave those secrets and login state
    # to the user rather than copying them into the Nix store.
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn ["codex"] selectedApplications;
      };
    };

    outputs.home.packages = [codex];
  }
