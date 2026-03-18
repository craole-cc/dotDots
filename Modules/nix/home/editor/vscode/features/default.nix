{
  lix,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.types.options) mkTrue mkFalse;
  inherit (lib.attrsets) listToAttrs;

  load = path: import path {inherit lix lib pkgs inputs;};

  allFeatures = map load [
    ./ai.nix
    ./appearance.nix
    ./decorations.nix
    ./infrastructure.nix
    ./markup.nix
    ./nix.nix
    ./productivity.nix
    ./scripting.nix
    ./systems.nix
    ./vcs.nix
    ./web.nix
  ];

  mkOption = f:
    if f.default
    then mkTrue f.description
    else mkFalse f.description;
in {
  features = listToAttrs (map (f: {
      name = f.name;
      value = f.feature;
    })
    allFeatures);
  options = listToAttrs (map (f: {
      name = f.name;
      value = mkOption f;
    })
    allFeatures);
}
