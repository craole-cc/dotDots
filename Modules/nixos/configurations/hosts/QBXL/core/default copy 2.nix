# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{pkgs, ...}: let
  alpha = "craole";
  dots = "/home/${alpha}/.dots";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in {
  imports = [
    <nixos-wsl/modules>
    (import "${home-manager}/nixos")
  ];
  wsl.enable = true;
  wsl.defaultUser = alpha;

  system.stateVersion = "24.11";

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
        alpha
      ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  environment = {
    variables = {
      EDITOR = "hx";
      VISUAL = "code";
      DOTS = dots;
    };
    systemPackages = with pkgs; [
      (writeScriptBin ".dots" ''
        exec "${dots}/Bin/shellscript/project/.dots" "$@"
      '')
      alejandra
      curl
      devenv
      fd
      fzf
      gitui
      helix
      jq
      nil
      nixd
      nix-index
      nixfmt-rfc-style
      ripgrep
      sd
      shfmt
      shellcheck
      tldr
      tokei
      undollar
      wget
    ];
  };
  programs = {
    bat.enable = true;
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
    lazygit.enable = true;
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    users.${alpha} =
      # { osConfig, ... }:
      {
        imports = [./home.nix];
        # home = {
        # inherit (osConfig.system) stateVersion;
        # };
        # programs = {
        # home-manager.enable = true;
        # atuin = {
        # enable = true;
        # daemon.enable = true;
        # enableBashIntegration = true;
        # };
        # };
      };
  };
}
