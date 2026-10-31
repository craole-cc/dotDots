{
  lix ? (import ../.. {}).libraries.default,
  pkgs ? import <nixpkgs> {},
  inputs ? {},
}: let
  inherit (lix) lib;
  catalogue = import ../../Libraries/nix/sources/data/tools.nix {_ = lix;};
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
  existingYaziShortcuts = selected ? yaziProjects && selected ? yaziCC && selected ? yaziDots && selected ? yaziYazi;
  existingFormatterShortcuts = catalogue.alejandra.aliases ? aljCheck && catalogue.alejandra.aliases ? aljHere && catalogue.alejandra.aliases ? aljQuiet;
  existingGitHelpers = catalogue.git.aliases ? gitFetch && catalogue.git.aliases ? gitStatus;
  inactiveBinary = !(selected ? git);
  inactiveDependency = !(selected ? yaziThenDate);
  activeDependency = withDate ? yaziThenDate;
  installedOverride = (toolkit.binariesFor [overridden]).fixture-command == "${overridden}/bin/fixture-command";
  unregisteredPackage = unregisteredBinaries.fixture-command == "${unregistered}/bin/fixture-command";
  unregisteredDoesNotSelectOtherTools = builtins.attrNames unregisteredBinaries == ["fixture-command"];
  allCoreutils = withDate ? cat && withDate ? cp && withDate ? sort && withDate ? uniq;
  listingShortcuts = listing.aliases ? lsdLong && listing.aliases ? lsdTree && listing.aliases ? lsdRecursive && listing.aliases ? ezal && listing.aliases ? et && listing.aliases ? er;
  binariesSeparateFromShortcuts = listing.binaries ? ls && !(listing.aliases ? ls);
  inactiveListingShortcuts = !(selected ? lsdLong || selected ? ezal);
}
