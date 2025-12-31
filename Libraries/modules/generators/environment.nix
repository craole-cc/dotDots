{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (_.lists.predicates) isIn;
  inherit (_.applications.resolution) editors browsers terminals launchers bars;

  mkEnvironment = {
    host,
    pkgs,
    packages, # TODO: We shouldn't need this as pkgs should be enough
    ...
  }: let
    user = host.users.data.primary or {};
    apps = user.applications or {};
    wm = host.interface.windowManager or null;
    de = host.interface.desktopEnvironment or null;
    dp = host.interface.displayProtocol or "wayland";
    dm = host.interface.displayManager or null;
    shell = host.interface.shell or null;
    prompt = host.interface.prompt or null;
    dots = host.paths.dots or null;
    system = pkgs.stdenv.hostPlatform.system;

    # useDms = wm == "niri" || wm == "hyprland";
    useDms = false;

    # Get all packages with resolved inputs and system
    editorPkgs = editors.packages {
      inherit pkgs system;
      inputs = packages;
      editorConfig = apps.editor or {};
    };

    browserPkgs = browsers.packages {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.browser or {};
    };

    terminalPkgs = terminals.packages {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.terminal or {};
    };

    launcherPkgs = launchers.packages {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.launcher or {};
    };

    barPkgs = bars.packages {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.bar or {};
    };

    # Get commands with resolved inputs and system
    editorCmds = editors.commands {
      inherit pkgs system;
      inputs = packages;
      editorConfig = apps.editor or {};
    };

    browserCmds = browsers.commands {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.browser or {};
    };

    terminalCmds = terminals.commands {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.terminal or {};
    };

    launcherCmds = launchers.commands {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.launcher or {};
    };

    barCmds = bars.commands {
      inherit pkgs system;
      inputs = packages;
      appConfig = apps.bar or {};
    };
  in {
    environment = {
      systemPackages =
        editorPkgs
        ++ browserPkgs
        ++ terminalPkgs
        ++ launcherPkgs
        ++ barPkgs;

      shellAliases = {
        ll = "lsd --long --git --almost-all";
        lt = "lsd --tree";
        lr = "lsd --long --git --recursive";
        edit-dots = "$EDITOR ${dots}";
        ide-dots = "$VISUAL ${dots}";
        push-dots = "gitui --directory ${dots}";
        repl-host = "nix repl ${dots}#nixosConfigurations.$(hostname)";
        repl-dots = "nix repl ${dots}#repl";
        switch-dots = "sudo nixos-rebuild switch --flake ${dots}";
        nxs = "push-dots; switch-dots";
        nxu = "push-dots; switch-dots; topgrade";
      };

      sessionVariables =
        {
          DOTS = dots;
          EDITOR = editorCmds.editor;
          VISUAL = editorCmds.visual;
          BROWSER = browserCmds.primary;
          TERMINAL = terminalCmds.primary;
          LAUNCHER = launcherCmds.primary;
          BAR = barCmds.primary;
        }
        // (
          optionalAttrs (dp == "wayland") {
            #? For Clutter/GTK apps
            CLUTTER_BACKEND = "wayland";

            #? For GTK apps
            GDK_BACKEND = "wayland";

            #? Required for Java UI apps on Wayland
            _JAVA_AWT_WM_NONREPARENTING = "1";

            #? Enable Firefox native Wayland backend
            MOZ_ENABLE_WAYLAND = "1";

            #? Force Chromium/Electron apps to use Wayland
            NIXOS_OZONE_WL = "1";

            #? Qt apps use Wayland
            QT_QPA_PLATFORM = "wayland";

            #? Disable client-side decorations for Qt apps
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

            #? Auto scale for HiDPI displays
            QT_AUTO_SCREEN_SCALE_FACTOR = "1";

            #? SDL2 apps Wayland backend
            SDL_VIDEODRIVER = "wayland";

            #? Allow software rendering fallback on Nvidia/VM
            WLR_RENDERER_ALLOW_SOFTWARE = "1";

            #? Disable hardware cursors on Nvidia/VM
            WLR_NO_HARDWARE_CURSORS = "1";

            #? Indicate Wayland session to apps
            XDG_SESSION_TYPE = "wayland";
          }
        );
    };
    programs = {
      bash = {
        enable = isIn "bash" ([shell] ++ (user.shells or []));
        blesh.enable = true;
        undistractMe.enable = true;
      };

      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      hyprland = {
        enable = wm == "hyprland";
        withUWSM = true;
      };

      niri = {
        enable = wm == "niri";
      };

      obs-studio = {
        enable = isIn ["video" "webcam"] (host.functionalities or []);
        enableVirtualCamera = true;
      };

      starship = {
        enable = prompt == "starship";
      };

      xwayland.enable = true;
    };

    services = {
      iio-niri.enable = wm == "niri";

      desktopManager = {
        cosmic = {
          enable = de == "cosmic";
          showExcludedPkgsWarning = false;
        };

        gnome = {
          enable = de == "gnome";
        };

        plasma6 = {
          enable = de == "plasma";
        };
      };

      displayManager = {
        autoLogin = {
          enable = user.autoLogin or false;
          user = user.name or null;
        };

        cosmic-greeter = {
          enable = de == "cosmic" && !useDms;
        };

        dms-greeter = {
          enable = useDms;
        };

        gdm = {
          enable = dm == "gdm" && !useDms;
          wayland = dp == "wayland";
        };

        sddm = {
          enable = dm == "sddm" && !useDms;
          wayland.enable = dp == "wayland";
        };

        ly = {
          enable = dm == "ly";
        };
      };
    };

    systemd.services = optionalAttrs (dm == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };
  };

  mkFonts = {
    pkgs,
    packages ? (with pkgs; [
      #~@ Monospace
      maple-mono.NF
      monaspace
      victor-mono

      #~@ System
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ]),
    emoji ? ["Noto Color Emoji"],
    monospace ? ["Maple Mono NF" "Monaspace Radon"],
    serif ? ["Noto Serif"],
    sansSerif ? ["Noto Sans"],
    ...
  }: {
    fonts = {
      inherit packages;
      enableDefaultPackages = true;
      fontconfig = {
        enable = true;
        hinting = {
          enable = true; # TODO: This should depend on the host specs
          style = "slight";
        };
        antialias = true;
        subpixel.rgba = "rgb";
        defaultFonts = {inherit emoji monospace serif sansSerif;};
      };
    };
  };

  mkLocale = {host, ...}: let
    loc = host.localization or {};
  in {
    time = {
      timeZone = loc.timeZone or null;
      hardwareClockInLocalTime = isIn "dualboot-windows" (host.functionalities or []);
    };

    location = {
      latitude = loc.latitude or null;
      longitude = loc.longitude or null;
      provider = loc.locator or "geoclue2";
    };

    i18n = {
      defaultLocale = loc.defaultLocale or null;
    };
  };
  exports = {inherit mkEnvironment mkFonts mkLocale;};
in
  exports // {_rootAliases = exports;}
