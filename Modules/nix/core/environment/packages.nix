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
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package;
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

    # The llm-agents input repackages the vendors' desktop clients for NixOS.
    # ChatGPT itself is OpenAI's official Linux binary; Claude is Anthropic's
    # official Linux package; Hermes Desktop is the native Nous desktop shell.
    aiDesktop = optionals isLinux [
      inputs.ai.packages.${system}.chatgpt
      inputs.ai.packages.${system}.hermes-desktop
      inputs.ai.packages.${system}.claude-desktop
    ];

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

    common = editor ++ browser ++ terminal ++ launcher ++ bar ++ aiDesktop;
    machine = wayland ++ linux ++ darwin;
    overall = default ++ common ++ machine;
  in {
    inherit
      editor
      browser
      terminal
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
