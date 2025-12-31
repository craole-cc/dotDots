{
  _,
  src,
  ...
}: let
  inherit (_.modules.resolution) flakeAttrs byPaths;

  modules = {
    nixpkgs = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "nixpkgs";
        paths = [
          ["nixosCore"]
          ["nixPackages"]
          ["nixosPackages"]
          ["nixosPackagesUnstable"]
          ["nixpkgs-unstable"]
          ["nixosPackagesStable"]
          ["nixpkgs-stable"]
        ];
      };

    nixpkgs-stable = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "nixpkgs-stable";
        paths = [
          ["nixosPackagesStable"]
          ["nixpkgs-stable"]
          ["nixpkgs"]
        ];
      };

    nixpkgs-unstable = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "nixpkgs-unstable";
        paths = [
          ["nixosPackagesUnstable"]
          ["nixpkgs-unstable"]
          ["nixpkgs"]
        ];
      };

    nix-darwin = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "nix-darwin";
        paths = [
          ["darwin"]
          ["nixDarwin"]
          ["darwinNix"]
        ];
      };
    home-manager = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "home-manager";
        paths = [
          ["nixHomeManager"]
          ["nixosHome"]
          ["nixHome"]
          ["homeManager"]
          ["home"]
        ];
      };

    fresh-editor = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "fresh-editor";
        paths = [
          ["fresh"]
          ["freshEditor"]
          ["editorFresh"]
        ];
      };
    helix = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "helix";
        paths = [
          ["helix-editor"]
          ["hx"]
          ["helixEditor"]
          ["editorHelix"]
          ["editorHX"]
        ];
      };
    noctalia-shell = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "noctalia-shell";
        paths = [
          ["shellNoctalia"]
          ["noctalia-dev"]
          ["noctalia"]
        ];
      };

    dank-material-shell = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "dank-material-shell";
        paths = [
          ["shellDankMaterial"]
          ["shellDank"]
          ["dank-material"]
          ["dank"]
          ["dms"]
        ];
      };

    nvf = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "nvf";
        paths = [
          ["editorNeovim"]
          ["neovim"]
          ["nvim"]
          ["neovimFlake"]
          ["neoVim"]
        ];
      };

    plasma = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "plasma";
        paths = [
          ["shellPlasma"]
          ["plasma-manager"]
          ["plasmaManager"]
          ["kde"]
        ];
      };

    treefmt = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "treefmt";
        paths = [
          ["treeFormatter"]
          ["fmtree"]
          ["treefmt-nix"]
        ];
      };
    vscode-insiders = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "vscode-insiders";
        paths = [
          ["vscode"]
          ["code"]
          ["code-insiders"]
          ["vsc"]
          ["VSCode"]
          ["editorVscode"]
          ["editorVscodeInsiders"]
          ["vscode-insiders-nix"]
        ];
      };
    zen-browser = {path ? src}:
      byPaths {
        attrset = (flakeAttrs {inherit path;}).inputs or {};
        default = "zen-browser";
        paths = [
          ["browserZen"]
          ["firefoxZen"]
          ["zen"]
          ["zenBrowser"]
          ["zenFirefox"]
          ["twilight"]
        ];
      };
  };

  packages = {
  };
in {
  inherit modules packages;
  _rootAliases = {};
}
