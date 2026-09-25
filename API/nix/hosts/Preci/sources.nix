{
  inputs ? null,
  lib,
  system,
  #? Passed in from configuration.nix: the icon/konsole derivations below key
  #? off the configured flavor/accent per user, and the konsole one titlecases
  #? the flavor name.
  aesthetics,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap unique;
  inherit (lib.strings) capitalize concatMapStringsSep;
  /**
  Pinned sources for the non-flake build.

  Each entry is fetched by commit (`rev`) and verified by `sha256`, so the
  result is reproducible. A branch name in `rev` (main, master,
  nixos-unstable) cannot be pinned, because the tarball changes under a fixed
  hash.

  To bump an input:
    1. Set `rev` to the new commit hash.
    2. Set `sha256 = lib.fakeSha256;`
    3. Rebuild. Nix fails with `specified: ... got: sha256:<hash>`.
    4. Paste that `<hash>` into `sha256` and rebuild again.

  `nixpkgs` should match the commit of the active channel, or `<nixpkgs>`
  (used by nixos-rebuild) and `sources.nixpkgs` will disagree.
    Get it with:
      cat /nix/var/nix/profiles/per-user/root/channels/nixos/.git-revision

  `dots` is intentionally unpinned so the local repo can move freely.
  */
  normalize = {
    owner,
    repo,
    rev,
    sha256 ? null,
    type ? "github",
  }: {
    inherit type owner repo rev sha256;
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
  };

  #? Uses sha256 when provided (reproducible), or fetches raw tarball when omitted/null (unpinned)
  fetchSrc = src:
    if src ? sha256 && src.sha256 != null && src.sha256 != ""
    then fetchTarball {inherit (src) url sha256;}
    else fetchTarball src.url;

  fetchMod = {
    name,
    path ? null,
    default ? null,
    enabled ? true,
  }:
    if !enabled
    then {} #? Returns an empty valid module!
    else if inputs ? ${name}
    then inputs.${name}.nixosModules.${name} or inputs.${name}
    else let
      fetched = fetchSrc revision.${name};
    in
      if path != null
      then import "${fetched}/${path}"
      else default fetched;

  revision = {
    nixpkgs = normalize {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
      sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
    };

    home-manager = normalize {
      owner = "nix-community";
      repo = "home-manager";
      rev = "4900baf1e219645e4a2acba35723852b2091bc20";
      sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
    };

    dots = normalize {
      owner = "craole-cc";
      repo = "dotDots";
      rev = "main";
    };

    nix-index = normalize {
      owner = "nix-community";
      repo = "nix-index-database";
      rev = "9ad722673ab3b3f91f02135e53775825b240b869";
      sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
    };

    catppuccin = normalize {
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

  packages = {
    nixpkgs = let
      config.allowUnfree = true;
    in
      if inputs ? nixpkgs
      then import inputs.nixpkgs {inherit system config;}
      else import (fetchSrc revision.nixpkgs) {inherit config;};

    home-manager = fetchMod {
      name = "home-manager";
      path = "nixos";
    };

    dots =
      inputs.dots or (fetchSrc revision.dots);

    catppuccin = fetchMod {
      name = "catppuccin";
      path = "modules/nixos";
    };

    nix-index = fetchMod {
      name = "nix-index";
      path = "nixos-module.nix";
    };

    icons = let
      papirus = with packages.nixpkgs;
        catppuccin-papirus-folders.override {
          inherit (aesthetics.primary.theme.dark) flavor accent;
        };
    in {
      buuf-nestort = with packages.nixpkgs;
        stdenvNoCC.mkDerivation {
          pname = "buuf-nestort";
          version = "2026-07-29";
          src = fetchgit {inherit (revision.buuf-nestort) url rev hash;};
          dontBuild = true;
          dontFixup = true;
          installPhase = ''
            mkdir -p $out/share/icons/buuf-nestort
            cp -r . $out/share/icons/buuf-nestort
            chmod -R u+w $out/share/icons/buuf-nestort
            sed -i 's/^Inherits=.*/Inherits=oxygen,breeze,Adwaita,hicolor/' \
              $out/share/icons/buuf-nestort/index.theme
          '';
        };
      Papirus-Dark = papirus;
      Papirus-Light = papirus;
    };

    catppuccin-konsole = let
      flavors = unique (
        concatMap
        (user: with user.theme; [dark.flavor light.flavor])
        (attrValues aesthetics.users)
      );
      pname = "catppuccin-konsole";
    in
      with packages.nixpkgs;
        stdenvNoCC.mkDerivation {
          inherit pname;
          version = "3b64040";
          src = fetchFromGitHub {
            inherit (revision.${pname}) owner repo rev hash;
          };
          dontBuild = true;
          dontFixup = true;
          installPhase = ''
            mkdir -p $out/share/konsole
            ${
              concatMapStringsSep "\n" (flavor: ''
                cp "$(find . -iname '*${flavor}*.colorscheme' | head -n1)" \
                  $out/share/konsole/Catppuccin-${capitalize flavor}.colorscheme
              '')
              flavors
            }
          '';
        };
  };
in
  packages // {inherit revision;}
