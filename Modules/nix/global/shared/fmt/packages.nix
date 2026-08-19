{
  lix,
  pkgs,
  flake,
  ...
}: let
  inherit (flake) inputs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.sources.packages) pkgsFrom;

  sources = {
    git = null;
    actionlint = null;
    alejandra = null;
    dprint = null;
    harper = null;
    leptosfmt = null;
    rustfmt = null;
    shellcheck = null;
    shfmt = null;
    statix = null;
    stylua = null;
    tombi = null;
    treefmt = "treefmt";
    typos = null;
    typstyle = null;
  };

  resolved = pkgsFrom {
    inherit inputs pkgs sources;
    required = true;
  };
in {
  inherit (resolved) packages;
  binaries = mapAttrs (_: pkg: pkg.paths.exe) resolved;
}
