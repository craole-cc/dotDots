{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.home-manager.enable = true;

  home = {
    username = "craole";
    homeDirectory = "/home/craole";
    stateVersion = "23.05";

    # Packages that should be installed to the user profile.
    packages = [
      # System Info
      # nix-output-monitor
      macchina # System info fetch written in Rust
      neofetch # System info fetch
      btop # Realtime system monitoring dashboard
      iotop # io monitoring
      iftop # network monitoring

      # System Tools
      sysstat
      lm_sensors # for `sensors` command
      ethtool
      pciutils # lspci
      usbutils # lsusb
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files

      # Utilities
      ripgrep # recursively searches directories for a regex pattern
      jq # A lightweight and flexible command-line JSON processor
      yq-go # yaml processer https://github.com/mikefarah/yq
      exa # A modern replacement for ‘ls’
      lsd # A modern replacement for ‘ls’
      fzf # A command-line fuzzy finder
      nnn # terminal file manager
      gnused
      gawk
      gnumake
      gnupg
      gnutar
      zip
      xz
      unzip
      p7zip
      file
      which
      tree
      zstd

      # networking tools
      mtr # A network diagnostic tool
      iperf3
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provide the command `drill`
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      nmap # A utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses

      # misc
      cowsay

      # nix related
      nix-output-monitor

      # productivity
      hugo # static site generator
      glow # markdown previewer in terminal
    ];
  };
}
