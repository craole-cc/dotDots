{
  config,
  lix,
  locale,
  options,
  user,
  ...
}: let
  inherit (lix.toolkit) write packages;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.lists.predicates) isIn;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.sources.access) getExe;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) anything bool;
  dom = "communication";
  mod = "thunderbird";
  context = mkContext {inherit config dom mod;};
  inherit (context) cfg;
  setup = write.rust {
    name = "thunderbird-google-setup";
    src = ./thunderbird-google.rs;
    inputs = [packages.xdg-utils];
  };
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = isIn mod (user.packages.communication or []);
      };
      package = mkOption {
        inherit (options.programs.${mod}.package) type description;
        default = packages.${mod};
      };
      autostart = mkOption {
        type = bool;
        default = true;
        description = "Start Thunderbird automatically at desktop login.";
      };
      extraPackages = mkOption {
        inherit (options.home.packages) type;
        default = [setup];
        description = "Additional packages installed alongside Thunderbird.";
      };
      configFiles = mkOption {
        type = attrsOf (attrsOf anything);
        default = {
          "thunderbird/google.example.env".source = ./google.example.env;
          "thunderbird/google.example.toml".source = ./google.example.toml;
        };
        description = "Configuration files installed for Thunderbird.";
      };
      profiles = mkOption {
        type = attrsOf (attrsOf anything);
        description = "Thunderbird profile definitions, evaluated by Home Manager.";
        default.google = {
          isDefault = true;
          settings."calendar.timezone.local" = locale.timeZone;
        };
      };
    };
    outputs = {
      home.packages = cfg.extraPackages;
      xdg.configFile =
        cfg.configFiles
        // optionalAttrs cfg.autostart {
          "autostart/thunderbird.desktop".text = ''
            [Desktop Entry]
            Type=Application
            Name=Thunderbird
            Exec=${getExe cfg.package}
            Terminal=false
          '';
        };
      programs.${mod} = {
        inherit (cfg) enable package profiles;
      };
    };
  }
