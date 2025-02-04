{ config, lib, ... }:
let
  inherit (lib.lists) elem;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;

  inherit (config) DOTS;
  inherit (DOTS.interface)
    manager
    isMinimal
    fonts
    ;
  inherit (DOTS.users.alpha) loginAutomatically name;

  base = "services";
  cfg = DOTS.${base};

in
{
  options.DOTS.${base} = mkOption {
    description = "The configuration for {{mod}}";
    default = {
      displayManager = {
        enable = (!isMinimal);
        autoLogin = {
          enable = loginAutomatically;
          user = name;
        };
        # sddm = {
        #   enable = manager != null && manager != "xfce" && manager != "none" && manager != "pantheon";
        #   wayland.enable = manager == "hyprland" || manager == "river" || manager == "sway";
        # };
        sddm = {
          enable =
            !elem manager [
              null
              "none"
              "xfce"
              "pantheon"
            ];
          wayland.enable = elem manager [
            "hyprland"
            "sway"
            "river"
          ];
        };
      };
      gnome = {
        gnome-keyring.enable = !isMinimal;
      };
      kmscon = with fonts.console; {
        enable = isMinimal;
        autologinUser = if loginAutomatically then name else null;
        extraConfig = "font-size=${toString size}";
        extraOptions = "--term xterm-256color";
        fonts = sets;
      };
      blueman.enable = (!isMinimal);
      pipewire =
        let
          enable = (!isMinimal);
        in
        {
          inherit enable;
          alsa = {
            inherit enable;
            support32Bit = true;
          };
          pulse = {
            inherit enable;
          };
          jack = {
            inherit enable;
          };
          extraConfig.pipewire."92-low-latency" = {
            context.properties.default.clock = {
              rate = 48000;
              quantum = 32;
              min-quantum = 32;
              max-quantum = 32;
            };
          };
        };
      tailscale.enable = (!isMinimal);
    };
    type = attrs;
  };

  config.${base} = cfg;
}
