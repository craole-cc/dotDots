{_, ...}: let
  meta = {
    # TODO: Add the correct doc
    doc = ''
    '';

    exports = {
      internal = let
        functions = {inherit mkEnvironment mkLocale;};
        aliases = {};
      in
        {inherit functions aliases;}
        // functions // aliases;
      external = {
        mkCoreEnvironment = mkEnvironment;
        mkCoreLocale = mkLocale;
      };
    };
  };

  inherit (_.lists.predicates) isIn;
  inherit
    (_.applications.resolution)
    editors
    browsers
    terminals
    launchers
    bars
    ;
  inherit (_.attrsets.construction) optionalAttrs;

  mkEnvironment = {
    host,
    pkgs,
    inputs,
    ...
  }: let
    #~@ Paths
    dots = host.paths.dots or null;
    wallpapers = host.paths.wallpapers or null;

    #~@ User profile
    user = host.users.data.primary or {};
    apps = user.applications or {};

    #~@ Host interface
    dp = host.interface.displayProtocol or "wayland";

    #~@ System
    inherit (pkgs.stdenv.hostPlatform) system;

    # mkApp = set: kind: {
    #   packages = set.packages {
    #     inherit pkgs system inputs;
    #     cfg = apps.${kind} or {};
    #   };
    #   commands = set.commands {
    #     inherit pkgs system inputs;
    #     cfg = apps.${kind} or {};
    #   };
    # };
    mkApp = set: kind:
      set {
        inherit pkgs system inputs;
        cfg = apps.${kind} or {};
      };
    editor = mkApp editors "editor";
    browser = mkApp browsers "browser";
    terminal = mkApp terminals "terminal";
    launcher = mkApp launchers "launcher";
    bar = mkApp bars "bar";
  in {
    environment = {
      systemPackages = with pkgs;
        [
          #~@ Nix - formatters, LSPs, cache, prefetchers
          alejandra # ? Opinionated Nix formatter (primary)
          nixfmt # ? RFC-style Nix formatter (secondary)
          cachix # ? Binary cache management CLI
          nil # ? Nix LSP for static analysis
          nixd # ? Nix language server daemon
          nix-index # ? Index nixpkgs files for nix-locate
          nix-info # ? System info helper for bug reports
          nix-output-monitor # ? Pretty build progress - pipe via nom
          nix-prefetch # ? Prefetch arbitrary sources
          nix-prefetch-docker # ? Prefetch Docker image hashes
          nix-prefetch-github # ? Prefetch GitHub repo hashes
          nix-prefetch-scripts # ? Common prefetch script helpers
          nvfetcher # ? Auto-update/pin flake sources

          #~@ System - core utilities, hardware inspection
          coreutils # ? GNU core utilities
          uutils-coreutils-noprefix # ? Rust reimplementation of coreutils
          findutils # ? GNU find, xargs, locate
          gawk # ? GNU awk for text processing
          getent # ? Query Name Service Switch databases
          gnused # ? GNU stream editor
          lshw # ? Detailed hardware lister
          pciutils # ? PCI tools - lspci
          usbutils # ? USB tools - lsusb
          gnome-randr # ? Display configuration for GNOME/Wayland
          wlr-randr # ? Display configuration for wlroots WMs
          procs # ? Modern ps replacement with tree view

          #~@ Files - navigation, search, sync, cleanup
          dua # ? Interactive disk usage analyzer (TUI)
          dust # ? Intuitive du replacement
          eza # ? Modern ls with git integration
          fd # ? Fast, user-friendly find alternative
          fzf # ? General-purpose fuzzy finder
          lsd # ? Stylish ls with icons and Git integration
          ouch # ? 7zip wrapper for [de]compressing archives with progress
          p7zip # ? 7zip CLI for archive management
          rsync # ? Fast incremental file sync/transfer
          sad # ? CLI find-and-replace (batch sed)
          trashy # ? Safe trash-aware rm alternative

          #~@ Network - transfer, GitHub
          curl # ? Command-line HTTP client
          wget # ? Non-interactive network downloader
          gh # ? Official GitHub CLI

          #~@ Dev - editors, VCS, data, media
          bat # ? Cat clone with syntax highlighting and paging
          gitui # ? Fast terminal UI for Git
          helix # ? Modal editor with native LSP + tree-sitter
          imagemagick # ? Image conversion and manipulation
          jql # ? JSON querying tool
          qimgv # ? Fast image viewer with minimal UI
          ripgrep # ? Fast recursive grep (rg)
          viu # ? Fast terminal image viewer with truecolor support

          #~@ Shell - monitoring, productivity, aesthetics
          btop # ? Rich resource monitor (htop replacement)
          fastfetch # ? Fast system info fetcher
          fend # ? Arbitrary-precision calculator REPL
          figlet # ? ASCII art text banners
          lolcat # ? Rainbow pipe colorizer
        ]
        ++ editor.packages
        ++ browser.packages
        ++ terminal.packages
        ++ launcher.packages
        ++ bar.packages;

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
        nxs = "push-dots; switch-dots"; # ? Stage, commit, rebuild
        nxu = "push-dots; switch-dots; topgrade"; # ? Full system upgrade
      };

      sessionVariables =
        {
          #~@ Paths
          DOTS = dots;
          WALLPAPERS = wallpapers;

          #~@ Default applications

          EDITOR = editor.commands.editor;
          VISUAL = editor.commands.visual;
          BROWSER = browser.commands.primary;
          TERMINAL = terminal.commands.primary;
          LAUNCHER = launcher.commands.primary;
          BAR = bar.commands.primary;
        }
        // (
          #~@ Wayland - toolkit and compositor backend hints
          optionalAttrs (dp == "wayland") {
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
          }
        );
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
      provider = loc.locator or "geoclue2";
    };

    #~@ Internationalization
    i18n.defaultLocale = loc.defaultLocale or null;
  };
in
  with meta.exports;
    internal
    // {
      __doc = meta.doc;
      __rootAliases = external;
    }
