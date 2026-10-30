{
  lix ? (import ../.. {}).libraries.default,
  pkgs ? import <nixpkgs> {},
  inputs ? {},
}: let
  inherit (lix) lib;
  toolkit = lix.sources.toolkit.mkToolkit {
    inherit pkgs inputs;
    sources.unused-tool = {
      transform = _package: throw "An inactive tool must not be resolved";
    };
    aliases = {
      yaziThenDate = {
        cmd = ["yazi"];
        after = [["date"]];
      };
    };
  };
  selected = toolkit.binariesFor [pkgs.yazi];
  withDate = toolkit.binariesFor [pkgs.yazi pkgs.coreutils];
  overridden = pkgs.yazi.overrideAttrs {version = "alias-selection-test";};
in {
  emptySelection = toolkit.binariesFor [] == {};
  activeBinary = selected.yazi == "${pkgs.yazi}/bin/yazi";
  activeShortcuts = selected ? y && selected ? yz && selected ? yp;
  inactiveBinary = !(selected ? git);
  inactiveDependency = !(selected ? yaziThenDate);
  activeDependency = withDate ? yaziThenDate;
  installedOverride = (toolkit.binariesFor [overridden]).yazi == "${overridden}/bin/yazi";
}
