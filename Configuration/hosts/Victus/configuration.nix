{...}: let
  getGitHub = {
    owner,
    repo,
    rev,
    sha256,
  }:
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
      inherit sha256;
    };

  inputs = {
    nixosCore = getGitHub {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "418468ac9527e799809c900eda37cbff999199b6";
      sha256 = "0p123456789abcdef0123456789abcdef0123456789";
    };

    nixosHome = getGitHub {
      owner = "nix-community";
      repo = "home-manager";
      rev = "36817384a6583478b8c03d269a7ab9339a7c5dfb";
      sha256 = "1q23456789abcdef0123456789abcdef0123456789";
    };
  };
in {
  nix.nixPath = ["nixpkgs=${inputs.nixosCore}"];
  imports = [
    (import ./. {inherit lib;})
    (import "${inputs.nixosHome}/nixos")
  ];
}
