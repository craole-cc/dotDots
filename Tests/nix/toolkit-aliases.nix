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
  listing = toolkit.commandsFor [pkgs.lsd pkgs.eza pkgs.coreutils];
  unregistered = {
    name = "unregistered-test-package";
    outPath = ./fixtures/toolkit-package;
  };
  unregisteredBinaries = toolkit.binariesFor [unregistered];
  overridden = unregistered // {pname = "yazi";};
in {
  emptySelection = toolkit.binariesFor [] == {};
  activeBinary = selected.yazi == "${pkgs.yazi}/bin/yazi";
  activeShortcuts = selected ? y && selected ? yz && selected ? yp;
  inactiveBinary = !(selected ? git);
  inactiveDependency = !(selected ? yaziThenDate);
  activeDependency = withDate ? yaziThenDate;
  installedOverride = (toolkit.binariesFor [overridden]).fixture-command == "${overridden}/bin/fixture-command";
  unregisteredPackage = unregisteredBinaries.fixture-command == "${unregistered}/bin/fixture-command";
  unregisteredDoesNotSelectOtherTools = builtins.attrNames unregisteredBinaries == ["fixture-command"];
  allCoreutils = withDate ? cat && withDate ? cp && withDate ? sort && withDate ? uniq;
  listingShortcuts = listing.aliases ? lsdLong && listing.aliases ? lsdTree && listing.aliases ? lsdRecursive && listing.aliases ? ezaLong && listing.aliases ? ezaTree && listing.aliases ? ezaRecursive;
  binariesSeparateFromShortcuts = listing.binaries ? ls && !(listing.aliases ? ls);
  inactiveListingShortcuts = !(selected ? lsdLong || selected ? ezaLong);
}
