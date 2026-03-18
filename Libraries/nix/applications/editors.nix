{
  _,
  lib,
  ...
}: let
  inherit (_.attrsets.resolution) vscodePackages;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optionals;

  __exports = {
    internal = {
      inherit
        mkVSCodeFeature
        mkVSCodeSubFeature
        mkHelixFeature
        mkNeovimFeature
        ;
    };
    external = __exports.internal;
  };

  mkVSCodeFeature = {
    enabled,
    extensions,
    userSettings ? {},
    pkgs,
    inputs,
  }: let
  in
    {
      extensions = optionals enabled (vscodePackages {
        inherit pkgs inputs;
        entries = extensions;
      });
    }
    // optionalAttrs enabled {inherit userSettings;};

  mkVSCodeSubFeature = {
    enabled,
    extensions ? [],
    userSettings ? {},
  }:
    {extensions = optionals enabled extensions;}
    // optionalAttrs enabled {inherit userSettings;};

  mkHelixFeature = {
    enabled,
    languages ? {},
    themes ? {},
  }:
    optionalAttrs enabled {inherit languages themes;};

  mkNeovimFeature = {
    enabled,
    plugins ? [],
    extraConfig ? "",
  }:
    optionalAttrs enabled {inherit plugins extraConfig;};
in
  __exports.internal // {_rootAliases = __exports.external;}
