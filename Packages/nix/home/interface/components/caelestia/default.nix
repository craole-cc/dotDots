{
  lib,
  pkgs,
  locale,
  style,
  paths,
  keyboard,
  user,
  lix,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge mkForce;
  inherit (keyboard) mod vimKeybinds;
  inherit (style) fonts;
  inherit (lix.lists.predicates) isIn;

  name = "caelestia";
  kind = "bar";

  # Caelestia is a Wayland shell — only valid under standalone WMs, not DEs
  supportedWMs = ["hyprland" "niri"];
  isSupported = isIn (user.interface.windowManager or null) supportedWMs;

  packages = with pkgs; [aubio brightnessctl ddcutil glibc libgcc cava lmsensors];

  programs = {
    ${name} = mkMerge [
      {enable = isSupported;}
      (import ./cli)
      (import ./settings {inherit locale fonts mkMerge paths vimKeybinds;})
    ];
  };

  services = {
    mako.enable = mkForce false;
  };

  cfg = {
    inherit name kind programs services;
    enable = isSupported;
  };
  home = {inherit packages;};
in {
  config = mkIf cfg.enable (mkMerge [
    {inherit cfg programs home services;}

    # Runtime guard — XDG_CURRENT_DESKTOP is set at login by the session manager.
    # This prevents the systemd service from starting when logged into a DE
    # (e.g. COSMIC, GNOME, Plasma), even though both a DE and WM are installed.
    # The "|" prefix is systemd's OR operator — any match allows startup.
    {
      systemd.user.services.caelestia = {
        Unit.ConditionEnvironment = [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
      };
    }

    (import ./hyprland.nix {inherit mod;})
  ]);
}
