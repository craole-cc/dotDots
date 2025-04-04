{
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (config.services) pipewire;
  inherit (specialArgs.paths) flake;
  gui =
    with config;
    services.xserver.enable || programs.hyprland.enable || services.displayManager.sddm.wayland.enable;
in
{
  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      config = {
        user = {
          name = "Your Name";
          email = "you@example.com";
        };
        init.defaultBranch = "main";
        safe.directory = with flake; [
          root
          local
        ];
      };
    };
    direnv = {
      enable = true;
      silent = true;
    };
    dconf = {
      enable = true;
    };
    # starship = {
    #   enable = true;
    # };
  };
  environment.systemPackages =
    with pkgs;
    [
      #| Core Utilities
      usbutils
      uutils-coreutils-noprefix
      busybox
      bat
      fzf
      ripgrep
      sd
      tldr
      fd
      jq
      nix-prefetch-scripts
      nix-prefetch
      nix-prefetch-github
      nix-prefetch-docker
      cachix

      #| Development
      nil
      nixd
      alejandra
      nixfmt-rfc-style
      nix-info
      shellcheck
      shfmt
      helix
      helix-gpt

      #| Filesystem
      dust
      eza
      pls
      lsd
      fastfetch
      cpufetch
      trashy
      conceal

      #| Utilities
      brightnessctl
      speedtest-go
      fend
      libqalculate
      radio-cli

      #| Shells
      #TODO: This is temporary, for testing .dotrc
      fish
      zsh
      powershell
      nushell
      starship
      figlet # Stylized Printing
    ]
    ++ (
      if gui then
        [
          ansel
          brave
          darktable
          dconf2nix
          dconf-editor
          drive
          freetube
          inkscape-with-extensions
          kitty
          microsoft-edge
          qbittorrent
          remmina
          shortwave
          via
          vscode-fhs
          warp-terminal
          whatsapp-for-linux
        ]
      else
        [ ]
    )
    ++ (
      if pipewire.enable then
        [
          pavucontrol
          easyeffects
        ]
      else
        [ ]
    )
    ++ (if pipewire.jack.enable then [ qjackctl ] else [ ]);
}
