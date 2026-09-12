{_, ...}: let
  inherit (_.attrsets.resolution) vscodePackages;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.lists.construction) optionals;

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
  }:
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
    {extensions = optionals enabled extensions;} // optionalAttrs enabled {inherit userSettings;};

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
  __exports.internal // {__rootAliases = __exports.external;}
