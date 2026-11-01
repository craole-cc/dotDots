{
  mkAliasFamily,
  mkSource,
  replaceStrings,
  ...
}: {
  dms-shell = mkSource {
    categories = ["desktop-ui"];
    description = "Dank Material Shell";
    input = "dank-material-shell";
    aliases = mkAliasFamily "dms" {
      Call = {args = ["ipc" "call"];};
      Set = {args = ["ipc" "call" "settings" "set"];};
    };
    transform = {
      package,
      source,
      builders,
      ...
    }: let
      patchedSource = builders.applyPatches {
        name = "dms-patched-source";
        src = source;
        patches = [
          ../../patches/dms/theme-control.patch
          ../../patches/dms/catppuccin-matugen.patch
          ../../patches/dms/notification-scratchpad-activation.patch
        ];
      };
    in
      package.overrideAttrs (previous: {
        src = "${patchedSource}/core";
        postInstall =
          replaceStrings
          [source]
          ["${patchedSource}"]
          previous.postInstall;
        passthru =
          (previous.passthru or {})
          // {shellSource = "${patchedSource}/quickshell";};
      });
  };

  dux-calendar = mkSource {
    categories = ["desktop-ui"];
    description = "Dux Calendar";
    target = "dankcalendar";
  };

  ghostty = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "GPU-accelerated terminal emulator";
    aliases = mkAliasFamily "ghostty" {
      ListFonts = {
        args = ["+list-fonts"];
        description = "list available fonts";
      };
      ListFontsPage = {
        args = ["+list-fonts"];
        pipe = [["bat"]];
        description = "browse available fonts with bat";
      };
    };
  };

  kitty = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "GPU-accelerated terminal emulator with graphics support";
  };

  foot = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "lightweight Wayland terminal emulator";
  };

  warp-terminal = mkSource {
    categories = ["desktop-ui" "terminal"];
    description = "Warp terminal emulator";
    input = "warp-terminal";
    # exe = "warp";
  };

  nemo = mkSource {
    categories = ["desktop-ui"];
    description = "Nemo file manager with extensions";
    target = "nemo-with-extensions";
    exe = "nemo";
  };

  hyprpaper = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper daemon for Hyprland";
    aliases = mkAliasFamily "hyprpaper" {
      Config = {
        args = ["--config"];
        description = "start with a caller-specified configuration file";
      };
    };
  };

  quickshell = mkSource {
    categories = ["desktop-ui"];
    description = "QtQuick-based desktop shell";
    input = "quickshell";
    aliases = mkAliasFamily "quickshell" {
      Config = {
        args = ["--config"];
        description = "start a named configuration (caller supplies it)";
      };
      Kill = {
        args = ["kill"];
        description = "stop a running quickshell instance";
      };
      List = {
        args = ["list"];
        description = "list running quickshell instances";
      };
      Path = {
        args = ["--path"];
        description = "start from a caller-specified configuration path";
      };
    };
  };

  swaybg = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper utility for Sway";
    aliases = mkAliasFamily "swaybg" {
      Color = {
        args = ["--color"];
        description = "set a solid background color (caller supplies it)";
      };
      Fill = {
        args = ["--mode" "fill" "--image"];
        description = "set an image wallpaper scaled to fill the output (caller supplies the image)";
      };
      Image = {
        args = ["--image"];
        description = "set an image wallpaper (caller supplies the image)";
      };
    };
  };

  variety = mkSource {
    categories = ["desktop-ui"];
    description = "wallpaper changer with scheduling and effects";
    aliases = mkAliasFamily "variety" {
      Favorite = {
        args = ["--favorite"];
        description = "move the current wallpaper to favorites";
      };
      Next = {
        args = ["--next"];
        description = "switch to the next wallpaper";
      };
      Preferences = {
        args = ["--preferences"];
        description = "open the preferences window";
      };
      Previous = {
        args = ["--previous"];
        description = "switch to the previous wallpaper";
      };
      Quit = {
        args = ["--quit"];
        description = "quit the running instance";
      };
      TogglePause = {
        args = ["--toggle-pause"];
        description = "pause or resume wallpaper changes";
      };
      Trash = {
        args = ["--trash"];
        description = "move the current wallpaper to the trash";
      };
    };
  };
}
