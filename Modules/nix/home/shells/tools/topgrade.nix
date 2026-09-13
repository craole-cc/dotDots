{
  config,
  host,
  lix,
  user,
  ...
}: let
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  context = mkContext {
    inherit config;
    dom = "shells";
    sub = "tools";
    mod = "topgrade";
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = user.applications.utilities.topgrade.enable or false;
    };
    outputs.programs.topgrade = {
      enable = true;
      settings = {
        misc = {
          assume_yes = true;
          disable =
            if host.class == "nixos"
            then ["home_manager"]
            else [];
          set_title = false;
          cleanup = true;
        };
        commands = {
          "Run garbage collection on Nix store" = "nix-collect-garbage";
        };
      };
    };
  }
