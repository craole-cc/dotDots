# sections/interface.nix
{helpers, byCategory}: let
  inherit (helpers) mkSection mkCapabilityQueries;
  all = byCategory.interface;
in {
  inherit all;

  compositors = mkSection {
    set     = byCategory.compositor;
    grouped = {eq = ["role"]; fields = ["protocol" "maturity"];};
  };

  environments = mkSection {
    set     = byCategory.environment;
    grouped = {
      eq     = ["compositor" "scope"];
      member = ["panel" "layouts" "greeters"];
      fields = ["protocol" "maturity"];
    };
    extraQueries = groups:
      {inherit (groups.byLayouts) tiling floating stacking;}
      // groups.byScope;
  };

  greeters = mkSection {
    set          = byCategory.greeter;
    grouped      = {eq = ["kind" "toolkit"]; fields = ["protocol"];};
    extraQueries = groups: groups.byToolkit // groups.byKind;
  };

  notifiers = mkSection {
    set     = byCategory.notifier;
    grouped = {member = ["config.lang"]; fields = ["maturity" "protocol"];};
  };

  panels = mkSection {
    set        = byCategory.panel;
    grouped    = {eq = ["toolkit"]; member = ["config.lang" "engine"]; fields = ["maturity" "protocol"];};
    queryField = "toolkit";
  };

  protocols = mkSection {
    set          = byCategory.protocol;
    grouped      = {eq = ["surface"]; fields = ["capability" "maturity"];};
    extraQueries = groups:
      mkCapabilityQueries {set = byCategory.protocol;}
      // groups.bySurface;
  };
}
