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

  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable;

  dmsEnabled = ctx.wantsDmsShell.condition;
  primaryUser = host.users.data.primary or host.users.primary or {};
  primaryUserName = primaryUser.name or null;
  primaryHome =
    if primaryUserName != null && builtins.hasAttr primaryUserName config.users.users
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

      # Hyprland 0.55 does not select hyprland.lua merely because the file is
      # present. DMS requires the compositor to be launched explicitly with
      # `-c ~/.config/hypr/hyprland.lua`, so expose a dedicated UWSM session
      # whose argv is fully declarative.
      programs.uwsm = mkIf (cfg.enable && dmsEnabled) {
        enable = true;
        waylandCompositors.hyprland-dms = {
          prettyName = "Hyprland (DMS)";
          comment = "Hyprland using the Dank Material Shell Lua configuration";
          binPath = "/run/current-system/sw/bin/Hyprland";
          extraArgs = [
            "-c"
            hyprlandLua
          ];
        };
      };
    };
  }
