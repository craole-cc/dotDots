{
  config,
  lix,
  user,
  ...
}: let
  inherit (lix.toolkit) write packages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;
  inherit (lix.lists.predicates) elem;
  context = mkContext {
    inherit config;
    dom = "communication";
    mod = "thunderbird";
  };
  setup = write.rust {
    name = "thunderbird-google-setup";
    src = ./thunderbird-google.rs;
  };
in
  mkConfig {
    inherit context;
    options.enable = mkEnable {
      inherit context;
      condition = elem "thunderbird" (user.packages.communication or []);
    };
    outputs = {
      home.packages = [setup];
      xdg.configFile."thunderbird/google.env.example".source = ./google.env.example;
      programs.thunderbird = {
        enable = true;
        package = packages.thunderbird;
        profiles.google = {
          isDefault = true;
          settings."calendar.timezone.local" = "America/Jamaica";
        };
      };
    };
  }
