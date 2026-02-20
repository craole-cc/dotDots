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
    config,
    packages, # TODO: We shouldn't need this as pkgs should be enough
    ...
  }: let
    #~@ Host interface
    wm = host.interface.windowManager    or null;
    de = host.interface.desktopEnvironment or null;
    dp = host.interface.displayProtocol  or "wayland";
    dm = host.interface.displayManager   or null;
    shell = host.interface.shell            or null;
    prompt = host.interface.prompt           or null;

    #~@ User profile
    user = host.users.data.primary or {};
    apps = user.applications       or {};

    #~@ Paths
    dots = host.paths.dots       or null;
    wallpapers = host.paths.wallpapers or null;

    #~@ System
    system = pkgs.stdenv.hostPlatform.system;

    #~@ Derived state
    session =
      if wm != null
      then wm
      else de;
    hasGui = de != null || wm != null;
    # useDms = wm == "niri" || wm == "hyprland";
    useDms = false;

    #~@ Application packages — resolved per host
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

    #~@ Application commands — resolved per host
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
      systemPackages = with pkgs;
        [
          #~@ Nix — formatters, LSPs, cache, prefetchers
          alejandra #? Opinionated Nix formatter (primary)
          nixfmt #? RFC-style Nix formatter (secondary)
          cachix #? Binary cache management CLI
          nil #? Nix LSP for static analysis
          nixd #? Nix language server daemon
          nix-index #? Index nixpkgs files for nix-locate
          nix-info #? System info helper for bug reports
          nix-output-monitor #? Pretty build progress — pipe via nom
          nix-prefetch #? Prefetch arbitrary sources
          nix-prefetch-docker #? Prefetch Docker image hashes
          nix-prefetch-github #? Prefetch GitHub repo hashes
          nix-prefetch-scripts #? Common prefetch script helpers
          nvfetcher #? Auto-update/pin flake sources

          #~@ System — core utilities, hardware inspection
          coreutils #? GNU core utilities
          uutils-coreutils-noprefix #? Rust reimplementation of coreutils
          findutils #? GNU find, xargs, locate
          gawk #? GNU awk for text processing
          getent #? Query Name Service Switch databases
          gnused #? GNU stream editor
          lshw #? Detailed hardware lister
          pciutils #? PCI tools — lspci
          usbutils #? USB tools — lsusb
          gnome-randr #? Display configuration for GNOME/Wayland

          #~@ Files — navigation, search, sync, cleanup
          dua #? Interactive disk usage analyzer (TUI)
          dust #? Intuitive du replacement
          eza #? Modern ls with git integration
          lsd #? Stylish ls with icons and Git integration
          fd #? Fast, user-friendly find alternative
          fzf #? General-purpose fuzzy finder
          rsync #? Fast incremental file sync/transfer
          sad #? CLI find-and-replace (batch sed)
          trashy #? Safe trash-aware rm alternative

          #~@ Network — transfer, GitHub
          curl #? HTTP/S transfer tool
          wget #? Non-interactive network downloader
          gh #? Official GitHub CLI

          #~@ Dev — editors, VCS, data, media
          amp #? Minimal terminal text editor (Rust)
          helix #? Modal editor with native LSP + tree-sitter
          gitui #? Fast terminal UI for Git
          imagemagick #? Image conversion and manipulation
          jql #? JSON querying tool
          ripgrep #? Fast recursive grep (rg)

          #~@ Shell — monitoring, productivity, aesthetics
          bat #? Cat clone with syntax highlighting and paging
          btop #? Rich resource monitor (htop replacement)
          fastfetch #? Fast system info fetcher
          fend #? Arbitrary-precision calculator REPL
          figlet #? ASCII art text banners
          lolcat #? Rainbow pipe colorizer
          procs #? Modern ps replacement with tree view
        ]
        ++ editorPkgs
        ++ browserPkgs
        ++ terminalPkgs
        ++ launcherPkgs
        ++ barPkgs;

      shellAliases = {
        #~@ File listing
        ll = "lsd --long --git --almost-all";
        lt = "lsd --tree";
        lr = "lsd --long --git --recursive";

        #~@ Dotfiles management
        edit-dots = "$EDITOR ${dots}";
        ide-dots = "$VISUAL ${dots}";
        push-dots = "gitui --directory ${dots}";

        #~@ Nix REPL
        repl-host = "nix repl ${dots}#nixosConfigurations.$(hostname)";
        repl-dots = "nix repl ${dots}#repl";

        #~@ Rebuild shortcuts
        switch-dots = "sudo nixos-rebuild switch --flake ${dots}";
        nxs = "push-dots; switch-dots"; #? Stage, commit, rebuild
        nxu = "push-dots; switch-dots; topgrade"; #? Full system upgrade
      };

      sessionVariables =
        {
          #~@ Paths
          DOTS = dots;
          WALLPAPERS = wallpapers;

          #~@ Default applications
          EDITOR = editorCmds.editor;
          VISUAL = editorCmds.visual;
          BROWSER = browserCmds.primary;
          TERMINAL = terminalCmds.primary;
          LAUNCHER = launcherCmds.primary;
          BAR = barCmds.primary;

          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        }
        // (optionalAttrs (dp == "wayland") {
          #~@ Wayland — toolkit and compositor backend hints

          #? Clutter/GTK backend
          CLUTTER_BACKEND = "wayland";

          #? GTK backend
          GDK_BACKEND = "wayland";

          #? Java UI apps on Wayland
          _JAVA_AWT_WM_NONREPARENTING = "1";

          #? Firefox native Wayland backend
          MOZ_ENABLE_WAYLAND = "1";

          #? Chromium/Electron Wayland backend
          NIXOS_OZONE_WL = "1";

          #? Qt platform
          QT_QPA_PLATFORM = "wayland";

          #? Disable Qt client-side decorations
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

          #? Qt HiDPI auto-scaling
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";

          #? SDL2 Wayland backend
          SDL_VIDEODRIVER = "wayland";

          #? Software rendering fallback (Nvidia/VM)
          WLR_RENDERER_ALLOW_SOFTWARE = "1";

          #? Disable hardware cursors (Nvidia/VM)
          WLR_NO_HARDWARE_CURSORS = "1";

          #? XDG session type hint for apps
          XDG_SESSION_TYPE = "wayland";
        });
    };

    programs = {
      #~@ Shell
      bash = {
        enable = isIn "bash" ([shell] ++ (user.shells or []));
        blesh.enable = true;
        undistractMe.enable = true;
      };

      direnv = {
        enable = true;
        silent = true;
        settings.global = {
          log_format = "-";
          log_filter = "^$";
        };
      };

      starship.enable = prompt == "starship";

      #~@ Version control
      git = {
        enable = true;
        lfs.enable = true;
        prompt.enable = true;
      };

      #~@ Window managers
      hyprland = {
        enable = wm == "hyprland";
        withUWSM = true;
      };

      niri.enable = wm == "niri";

      #~@ Media
      obs-studio = {
        enable = isIn ["video" "webcam"] (host.functionalities or []);
        enableVirtualCamera = true;
      };

      #~@ Display
      xwayland.enable = true;
    };

    services = {
      #~@ Input
      iio-niri.enable = wm == "niri"; #? Sensor integration for niri

      #~@ Desktop environments
      desktopManager = {
        cosmic = {
          enable = de == "cosmic";
          showExcludedPkgsWarning = false;
        };

        gnome.enable = de == "gnome";
        plasma6.enable = de == "plasma";
      };

      #~@ Display manager
      displayManager = {
        autoLogin = {
          enable = user.autoLogin or false;
          user = user.name      or null;
        };

        defaultSession =
          if (session == "hyprland" && config.programs.hyprland.withUWSM)
          then "hyprland-uwsm"
          else session;

        #? COSMIC native greeter — disabled when DMS active
        cosmic-greeter.enable = de == "cosmic" && !useDms;
        dms-greeter.enable = useDms;

        gdm = {
          enable = dm == "gdm" && !useDms;
          wayland = dp == "wayland";
        };

        sddm = {
          enable = dm == "sddm" && !useDms;
          wayland.enable = dp == "wayland";
        };

        ly.enable = dm == "ly";
      };

      #~@ Hardware
      udisks2 = optionalAttrs hasGui {
        enable = true;
        mountOnMedia = true; #? Auto-mount removable media under /media
      };
    };

    #~@ Systemd — suppress redundant TTY sessions when using GDM
    systemd.services = optionalAttrs (dm == "gdm") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    xdg.portal = {
      enable = true;
      # config = {
      #   common."org.freedesktop.impl.portal.Settings" = ["darkman" "gnome"];
      # };
    };
  };

  mkLocale = {host, ...}: let
    loc = host.localization or {};
  in {
    #~@ Timezone
    time = {
      timeZone = loc.timeZone or null;
      hardwareClockInLocalTime = isIn "dualboot-windows" (host.functionalities or []);
    };

    #~@ Geolocation
    location = {
      latitude = loc.latitude or null;
      longitude = loc.longitude or null;
      provider = loc.locator  or "geoclue2";
    };

    #~@ Internationalization
    i18n.defaultLocale = loc.defaultLocale or null;
  };

  exports = {inherit mkEnvironment mkLocale;};
in
  exports // {_rootAliases = exports;}
