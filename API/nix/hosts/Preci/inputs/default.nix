{
  lix,
  system,
  inputs ? lix.flake.inputs or {},
  ...
}: let
  inherit (lix.fetchers) mkGitHubSource fetchSource fetchModule;

  resolveModule = args: fetchModule (args // {inherit inputs sources;});

  sources = {
    nixpkgs = mkGitHubSource {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
      sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
    };

    home-manager = mkGitHubSource {
      owner = "nix-community";
      repo = "home-manager";
      rev = "4900baf1e219645e4a2acba35723852b2091bc20";
      sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
    };

    dots = mkGitHubSource {
      owner = "craole-cc";
      repo = "dotDots";
      rev = "main";
    };

    nix-index = mkGitHubSource {
      owner = "nix-community";
      repo = "nix-index-database";
      rev = "9ad722673ab3b3f91f02135e53775825b240b869";
      sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
    };

    catppuccin = mkGitHubSource {
      owner = "catppuccin";
      repo = "nix";
      rev = "89b3eacf59d6b5eefbc2d69c3a4eb5aaf66d63bc";
      sha256 = "sha256-W5dvgFOuVs24X3G5tUb8C2IHU7ICXNvyGPiWWFjfbuo=";
    };

    catppuccin-konsole = {
      owner = "catppuccin";
      repo = "konsole";
      rev = "3b64040e3f4ae5afb2347e7be8a38bc3cd8c73a8";
      hash = "sha256-d5+ygDrNl2qBxZ5Cn4U7d836+ZHz77m6/yxTIANd9BU=";
    };

    buuf-nestort = {
      url = "https://git.disroot.org/eudaimon/buuf-nestort";
      rev = "ba218523983aec90f1e9facaefeeeeecdcf6d6a5";
      hash = "sha256-6aEM+rL7chkP83Rol6/F5jmG3mo6vALPk2pIvkUK1rU=";
    };
  };

  resolved = {
    nixpkgs = let
      config.allowUnfree = true;
    in
      if inputs ? nixpkgs
      then import inputs.nixpkgs {inherit system config;}
      else import (fetchSource sources.nixpkgs) {inherit config;};

    home-manager = resolveModule {
      name = "home-manager";
      path = "nixos";
    };

    dots = inputs.dots or (fetchSource sources.dots);

    catppuccin = resolveModule {
      name = "catppuccin";
      path = "modules/nixos";
    };

    nix-index = resolveModule {
      name = "nix-index";
      path = "nixos-module.nix";
    };
  };

  modules = [
    resolved.home-manager
    resolved.nix-index
    resolved.catppuccin
  ];
in
  resolved // {inherit modules; raw = sources;}
