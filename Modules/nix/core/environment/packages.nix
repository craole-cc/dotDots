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
  system = pkgs.stdenv.hostPlatform.system;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) listOf package;
  inherit (lix.applications.resolution) editors browsers terminals launchers bars;

  editorPkgs = editors.packages {
    inherit pkgs system inputs;
    editorConfig = apps.editor or {};
  };
  browserPkgs = browsers.packages {
    inherit pkgs system inputs;
    appConfig = apps.browser or {};
  };
  terminalPkgs = terminals.packages {
    inherit pkgs system inputs;
    appConfig = apps.terminal or {};
  };
  launcherPkgs = launchers.packages {
    inherit pkgs system inputs;
    appConfig = apps.launcher or {};
  };
  barPkgs = bars.packages {
    inherit pkgs system inputs;
    appConfig = apps.bar or {};
  };

  defaultPackages = with pkgs; [
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
    jql
    qimgv
    ripgrep
    viu

    #~@ Shell
    btop
    fastfetch
    fend
    figlet
    lolcat
  ];
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    default = mkOption {
      description = "Base system packages";
      default = defaultPackages;
      type = listOf package;
    };
    extra = mkOption {
      description = "Additional packages to install";
      default = [];
      type = listOf package;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      cfg.default
      ++ cfg.extra
      ++ editorPkgs
      ++ browserPkgs
      ++ terminalPkgs
      ++ launcherPkgs
      ++ barPkgs;
  };
}
