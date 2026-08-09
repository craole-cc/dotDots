{
  lib,
  config,
  pkgs,
  locale,
  style,
  paths,
  keyboard,
  inputsForHome,
  top,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.modules) mkIf mkMerge mkForce;
  inherit (keyboard) mod vimKeybinds;
  inherit (style) fonts;
  name = "caelestia";
  kind = "bar";
  enable =
    config ? programs.${name}
    && (inputsForHome ? ${name})
    && inputsForHome.${name}.isAllowed;
in {
config = lib.mkMerge [
    (mkIf enable (mkMerge [
    (import ./hyprland.nix {inherit mod;})
    {
      programs = mkMerge [
        (optionalAttrs enable {
          ${name} = mkMerge [
            {enable = true;}
            (import ./cli {})
            (import ./settings {inherit locale fonts mkMerge paths vimKeybinds;})
          ];
        })
      ];
      home = {
        packages = with pkgs; [
          aubio
          brightnessctl
          ddcutil
          glibc
          libgcc
          cava
          lm_sensors
        ];
      };
      services = {
        mako.enable = mkForce false;
      };

      systemd.user.services.caelestia = {
        Unit.ConditionEnvironment = [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
      };
    }
  ]))
    {${top}.output = mkIf enable (mkMerge [
    (import ./hyprland.nix {inherit mod;})
    {
      programs = mkMerge [
        (optionalAttrs enable {
          ${name} = mkMerge [
            {enable = true;}
            (import ./cli {})
            (import ./settings {inherit locale fonts mkMerge paths vimKeybinds;})
          ];
        })
      ];
      home = {
        packages = with pkgs; [
          aubio
          brightnessctl
          ddcutil
          glibc
          libgcc
          cava
          lm_sensors
        ];
      };
      services = {
        mako.enable = mkForce false;
      };

      systemd.user.services.caelestia = {
        Unit.ConditionEnvironment = [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
      };
    }
  ]);}
  ];
}
