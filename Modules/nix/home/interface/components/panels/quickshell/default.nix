{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "quickshell";
  };
  inherit (context) cfg;
  inherit (lix.modules.construction) mkConfig mkContext mkDefault;
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) package;
  inherit (lix.toolkit) packages;
in
  mkConfig {
    inherit context;
    options = {
      package = mkOption {
        description = "Package to use for QuickShell";
        default = packages.quickshell;
        type = package;
      };
    };

    outputs = {
      programs.quickshell = mkDefault {
        inherit (cfg) package;
      };
    };
  }
