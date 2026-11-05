{
  config,
  host,
  lix,
  ...
}: let
  dom = "interface";
  sub = "panels";
  mod = "dms-shell";
  context = mkContext {    inherit config dom sub mod;  };
  inherit (context) cfg top;

  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable;

  activePanel = config.${top}.resolved.interface.panels.active;
  dmsUsers = mapAttrs (_: _: {extraGroups = ["input"];}) (host.users.interactive or {});
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = activePanel == "dms-shell";
      };
    };
    outputs = {
      programs = {
        dms-shell.enable = cfg.enable;

        # DMS' screen-recording plugin invokes the native CLI directly. Use
        # the NixOS module rather than only adding the package so its privileged
        # KMS helper is configured correctly as well.
        gpu-screen-recorder.enable = cfg.enable;
      };

      # DMS uses evdev input state for Caps Lock OSD/indicators. Keep the
      # membership declarative instead of letting runtime setup mutate groups.
      users.users = dmsUsers;
    };
  }
