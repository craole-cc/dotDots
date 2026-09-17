{
  config,
  lix,
  pkgs,
  ...
}: let
  dom = "ai";
  sub = "agents";
  mod = "ollama";

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.types.primitives) anything package;

  context = mkContext {inherit config dom sub mod;};
  inherit (context) cfg;
in
  mkConfig {
    inherit context;

    # Ollama is a single host-local inference service.  Its model store and
    # GPU/runtime configuration consequently belong to NixOS, not to a user's
    # Home Manager profile.
    options = {
      enable = mkEnable {inherit context;};

      package = mkOption {
        type = package;
        default = pkgs.ollama;
      };

      # Forward the services.ollama interface, including host, port,
      # acceleration, models, loadModels, environmentVariables, sandbox, and
      # firewall policy. The upstream NixOS module remains the type authority.
      service = mkOption {
        type = anything;
        default.host = "127.0.0.1";
      };
    };

    outputs = {
      services.ollama = cfg.service // {inherit (cfg) enable package;};

      # The service owns the daemon, while the CLI is how users pull and
      # inspect models from the shared local store.
      environment.systemPackages = [cfg.package];
    };
  }
