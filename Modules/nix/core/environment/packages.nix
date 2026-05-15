{
  lix,
  config,
  host,
  lib,
  pkgs,
  inputs,
  top,
  ...
}: let
  dom = "environment";
  mod = "packages";
  cfg = config.${top}.${dom}.${mod};

  user = host.users.data.primary or {};
  apps = user.applications or {};
  inherit (pkgs.stdenv.hostPlatform) system;

  inherit (config.${top}.interface) displayProtocol;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals unique;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf package;
  inherit
    (lix.applications.resolution)
    editors
    browsers
    terminals
    launchers
    bars
    ;

  registry = let
    editor = editors.packages {
      inherit pkgs system inputs;
      cfg = apps.editor or {};
    };

    browser = browsers.packages {
      inherit pkgs system inputs;
      cfg = apps.browser or {};
    };

    terminal = terminals.packages {
      inherit pkgs system inputs;
      cfg = apps.terminal or {};
    };

    launcher = launchers.packages {
      inherit pkgs system inputs;
      cfg = apps.launcher or {};
    };

    bar = bars.packages {
      inherit pkgs system inputs;
      cfg = apps.bar or {};
    };

    wayland = optionals (displayProtocol == "wayland") (with pkgs; []);
    linux = optionals (pkgs.stdenv.isLinux) (with pkgs; [wl-clipboard xsel]);
    darwin = optionals (pkgs.stdenv.isDarwin) (with pkgs; []);

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

    common = editor ++ browser ++ terminal ++ launcher ++ bar;
    system = wayland ++ linux ++ darwin;
    all = default ++ common ++ system;
  in {
    inherit
      editor
      browser
      terminal
      launcher
      bar
      wayland
      linux
      darwin
      common
      system
      all
      ;
  };
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    default = mkOption {
      description = "Base system packages";
      default = registry.all;
      type = listOf package;
    };
    extra = mkOption {
      description = "Additional packages to install";
      default = [];
      type = listOf package;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = unique (cfg.default ++ cfg.extra);
    programs.xwayland.enable = true;
  };
}
