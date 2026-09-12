{
  config,
  lix,
  host,
  inputs,
  pkgs,
  top,
  ...
}: let
  dom = "environment";
  mod = "packages";

  inherit (lix.modules.construction) mkConfig mkContext mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.transformation) unique;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package;
  inherit (lix.applications.registry) resolve;
  inherit (lix.applications.runtime) resolvePackage;
  inherit
    (lix.applications.resolution)
    bars
    browsers
    editors
    launchers
    terminals
    ;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin system;

  context = mkContext {
    inherit
      config
      dom
      mod
      top
      ;
  };
  inherit (context) cfg ice;

  user = host.users.data.primary or {};
  apps = user.applications or {};
  displayProtocol = ice.displayProtocol or null;

  registry = let
    editor = editors.packages {
      inherit pkgs system inputs;
      config = apps.editor or {};
    };

    browser = browsers.packages {
      inherit pkgs system inputs;
      config = apps.browser or {};
    };

    terminal = terminals.packages {
      inherit pkgs system inputs;
      config = apps.terminal or {};
    };

    launcher = launchers.packages {
      inherit pkgs system inputs;
      config = apps.launcher or {};
    };

    bar = bars.packages {
      inherit pkgs system inputs;
      config = apps.bar or {};
    };

    # File managers are registry-native even though the older application
    # resolution helper has no explorer wrapper yet. Install every selected
    # role so GUI/TUI file-manager choices are not accidental transitive deps.
    explorerNames = filter (name: name != null) [
      (apps.explorer.primary or null)
      (apps.explorer.secondary or null)
      (apps.explorer.tertiary or null)
    ];
    explorer = unique (filter (pkg: pkg != null) (
      map (
        name: let
          app = resolve {
            value = name;
            category = explorer;
          };
        in
          resolvePackage {
            inherit app inputs pkgs system;
          }
      )
      explorerNames
    ));

    # AI desktop clients are registry-owned too. Resolve them through the same
    # normalized input contract as the rest of the application model so raw
    # flake aliases such as `ai` never leak into module consumers.
    aiNames = [
      "chatgpt"
      "hermes-desktop"
      "claude-desktop"
    ];
    aiDesktop = optionals isLinux (unique (filter (pkg: pkg != null) (
      map (
        name: let
          app = resolve {
            value = name;
            category = "ai";
          };
        in
          resolvePackage {
            inherit app inputs pkgs system;
          }
      )
      aiNames
    )));

    wayland = optionals (displayProtocol == "wayland") (with pkgs; [wl-clipboard]);
    linux = optionals isLinux (with pkgs; [xsel]);
    darwin = optionals isDarwin (with pkgs; [pngpaste]);

    default = with pkgs; [
      #~@ Nix
      alejandra
      nixfmt
      cachix
      nil
      nixd
      nix-index
      nix-info
      nix-output-monitor
      nix-prefetch
      nix-prefetch-docker
      nix-prefetch-github
      nix-prefetch-scripts
      nvfetcher

      #~@ System
      coreutils
      uutils-coreutils-noprefix
      findutils
      gawk
      getent
      gnused
      lshw
      pciutils
      usbutils
      gnome-randr
      wlr-randr
      procs

      #~@ Files
      dua
      dust
      eza
      fd
      fzf
      lsd
      ouch
      p7zip
      rsync
      sad
      trashy

      #~@ Network
      curl
      wget
      gh

      #~@ Dev
      bat
      gitui
      helix
      imagemagick
      imv
      jq
      jql
      nomacs
      qimgv
      ripgrep
      viu
      gum

      #~@ Shell
      btop
      fastfetch
      fend
      figlet
      lolcat
    ];

    common = editor ++ browser ++ terminal ++ explorer ++ launcher ++ bar ++ aiDesktop;
    machine = wayland ++ linux ++ darwin;
    overall = default ++ common ++ machine;
  in {
    inherit
      editor
      browser
      terminal
      explorer
      launcher
      bar
      aiDesktop
      wayland
      linux
      darwin
      common
      machine
      overall
      ;
  };
in
  mkConfig {
    inherit context;

    options = {
      enable = mkEnable {inherit context;};

      default = mkOption {
        description = "Base system packages";
        default = registry.overall;
        type = listOf package;
      };

      extra = mkOption {
        description = "Additional packages to install";
        default = [];
        type = listOf package;
      };
    };

    outputs = mkIf cfg.enable {
      environment.systemPackages = cfg.default ++ cfg.extra;
    };
  }
