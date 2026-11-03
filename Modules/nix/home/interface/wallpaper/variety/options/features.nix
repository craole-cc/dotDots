{lix, ...}: let
  inherit (lix.options.construction) mkFalse mkOption mkTrue;
  inherit (lix.types.primitives) float ints str;
  inherit (lix.types.combinators) enum listOf nullOr;
in {
  change = {
    onStart = mkFalse "Change when the application starts";
    enable = mkTrue "Enable wallpaper changer";
    interval = mkOption {
      type = ints.between 5 31536000;
      default = 3600;
      description = "Seconds between wallpaper changes (minimum 5).";
    };
  };

  internet = mkTrue "Use Internet access";
  safeMode = mkFalse "Enable safe operation for testing";

  quota = {
    enable = mkTrue "Enable quota management";
    size = mkOption {
      type = ints.between 50 100000000;
      default = 1000;
      description = "Download folder size cap in MB (minimum 50).";
    };
  };

  downloadPreferenceRatio = mkOption {
    type = float;
    default = 0.9;
  };

  wallhaven.apiKeyFile = mkOption {
    type = nullOr str;
    default = null;
    example = "/run/secrets/wallhaven";
    description = ''
      Path (as a string, so it never enters the Nix store) to a file
      holding the Wallhaven API key. It is substituted into variety.conf
      at activation time. Use alphanumeric keys only.
    '';
  };

  displayMode = mkOption {
    type = enum [
      "os"
      "smart"
      "zoom"
      "fill-with-black"
      "fill-with-blur"
      "gnome-zoom"
      "gnome-centered"
      "gnome-scaled"
      "gnome-stretched"
      "gnome-spanned"
      "gnome-wallpaper"
    ];
    default = "os";
    description = "Passed to the hook script as its fourth argument.";
  };

  autoRotate = mkTrue "Allow auto rotation";

  clipboard = {
    enable = mkFalse "Monitor clipboard for image URLs and fetch them";
    useWhitelist = mkTrue "Only fetch from predefined URL host";
    hosts = mkOption {
      type = listOf str;
      default = [
        "wallhaven.cc"
        "wallpapers.net"
        "flickr.com"
        "imgur.com"
        "deviantart.com"
        "interfacelift.com"
        "vladstudio.com"
        "imageshack.us"
        "deviantart.net"
        "imageshack.com"
      ];
    };
  };

  icon = mkOption {
    type = str;
    default = "Current";
    description = "Light, Dark, Current, 1-4, None, or a full image path.";
  };

  copyTo = {
    enable = mkFalse ''
      Copy each wallpaper to a world-readable folder (LightDM support).
      Leave off if that folder is also one of your sources, otherwise
      current wallpapers feed back into the pool.
    '';
    folder = mkOption {
      type = str;
      default = "Default";
    };
  };

  lockScreen = mkFalse ''
    Maps to change_lock_screen. Variety's stock lock screen script only
    knows KDE and GNOME, so keep it off on Hyprland.
  '';

  sync = mkFalse "Enable sync";
  stats = mkFalse "Enable stats";

  features = {
    smart = {
      enable = mkFalse "Variety smart enabled.";
      noticeShown = mkTrue "Variety smart notice shown.";
      registerShown = mkTrue "Variety smart register shown.";
    };
    stats = {
      noticeShown = mkTrue "Variety stats notice shown.";
    };
    preferred = {
      operations = mkOption {
        type = str;
        default = "Downloaded:Copy;Fetched:Move;Others:Copy";
        description = "Operations for preferred wallpapers.";
      };
    };
  };
}
