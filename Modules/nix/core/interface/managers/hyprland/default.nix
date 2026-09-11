{
  config,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "managers";
    mod = "hyprland";
  };
  inherit (context) cfg ctx;

  inherit (lix.attrsets.predicates) hasAttr;
  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable;

  dmsEnabled = ctx.wantsDmsShell.condition;
  primaryUser = host.users.data.primary or host.users.primary or {};
  primaryUserName = primaryUser.name or null;
  primaryHome =
    if primaryUserName != null && hasAttr primaryUserName config.users.users
    then config.users.users.${primaryUserName}.home
    else null;
  hyprlandLua =
    if primaryHome == null
    then "/dev/null"
    else "${primaryHome}/.config/hypr/hyprland.lua";
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable ({inherit context;} // ctx.wantsHyprland);
    };
    outputs = {
      assertions = [
        {
          assertion = !(cfg.enable && dmsEnabled) || primaryHome != null;
          message = "DMS-managed Hyprland requires a resolvable primary user's home directory";
        }
      ];

      programs.hyprland = {
        inherit (cfg) enable;
        withUWSM = true;
      };

      # Hyprland 0.55+ expects normal sessions to enter through start-hyprland,
      # which owns the watchdog lifecycle. Arguments after `--` are forwarded
      # to Hyprland, so keep the DMS Lua config selection explicit while letting
      # UWSM and Hyprland use their supported startup path.
      programs.uwsm = mkIf (cfg.enable && dmsEnabled) {
        enable = true;
        waylandCompositors.hyprland-dms = {
          prettyName = "Hyprland (DMS)";
          comment = "Hyprland using the Dank Material Shell Lua configuration";
          binPath = "/run/current-system/sw/bin/start-hyprland";
          extraArgs = [
            "--"
            "-c"
            hyprlandLua
          ];
        };
      };
    };
  }
