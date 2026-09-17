{
  config,
  lix,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "ollama";

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config dom sub mod;
  };
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    # Ollama is a single host-local inference service.  Its model store and
    # GPU/runtime configuration consequently belong to NixOS, not to a user's
    # Home Manager profile.
    options = {
      enable = mkEnable {inherit context;};
    };

    outputs = {
      services.ollama.enable = cfg.enable;

      # The service owns the daemon, while the CLI is how users pull and
      # inspect models from the shared local store.
      environment.systemPackages = [config.services.ollama.package];
    };
  }
