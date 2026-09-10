{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "panels";
    mod = "dms-shell";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  panel = config.${context.top}.resolved.interface.panel or null;
  dmsUsers = builtins.mapAttrs (_: _: {extraGroups = ["input"];}) (host.users.interactive or {});
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = panel == "dms-shell";
      };
    };
    outputs = {
      programs.dms-shell.enable = cfg.enable;

      # DMS uses evdev input state for Caps Lock OSD/indicators. Keep the
      # membership declarative instead of letting `dms setup` call usermod.
      users.users = dmsUsers;
    };
  }
