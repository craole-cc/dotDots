{
  _,
  src,
  ...
}: let
  normalize = {path ? src}: let
    res = _.inputs.resolution;
  in {
    #~@ Core
    nixpkgs = res.nixpkgs {inherit path;};
    nixpkgs-stable = res.nixpkgs-stable {inherit path;};
    nixpkgs-unstable = res.nixpkgs-unstable {inherit path;};
    nix-darwin = res.nix-darwin {inherit path;};
    home-manager = res.home-manager {inherit path;};

    #~@ Applications
    dank-material-shell = res.dank-material-shell {inherit path;};
    fresh-editor = res.fresh-editor {inherit path;};
    helix = res.helix {inherit path;};
    noctalia-shell = res.noctalia-shell {inherit path;};
    nvf = res.nvf {inherit path;};
    plasma = res.plasma {inherit path;};
    treefmt = res.treefmt {inherit path;};
    vscode-insiders = res.vscode-insiders {inherit path;};
    zen-browser = res.zen-browser {inherit path;};
  };

  normalizePackages = {path ? src}: let
    res = normalize {inherit path;};
  in {
    #~@ Core
    nixpkgs-stable = res.nixpkgs-stable.legacyPackages;
    nixpkgs-unstable = res.nixpkgs-unstable.legacyPackages;
    home-manager = res.home-manager.packages;

    #~@ Applications
    dank-material-shell = res.dank-material-shell.packages;
    fresh-editor = res.fresh-editor.packages;
    helix = res.helix.packages;
    noctalia-shell = res.noctalia-shell.packages;
    nvf = res.nvf.packages;
    plasma = res.plasma.packages;
    treefmt = res.treefmt.packages;
    vscode-insiders = res.vscode-insiders.packages;
    zen-browser = res.zen-browser.packages;
  };
in {
  inherit normalize normalizePackages;
  _rootAliases = {
    mkInputs = normalize;
    mkInputPackages = normalizePackages;
  };
}
