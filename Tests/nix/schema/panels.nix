{lix ? (import ../../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.access) length;
  inherit (lix.schema.ui) mkUI normalize;

  tests = {
    testNoEnvironmentHasNoActivePanel = {
      expr = (normalize {}).panels.active;
      expected = null;
    };
    testEnvironmentSelectsDms = {
      expr = (normalize {desktops = ["hyprland"];}).panels.active;
      expected = "dms-shell";
    };
    testDesktopSelectsItsPanel = {
      expr = (normalize {desktops = ["gnome"];}).panels.active;
      expected = "gnome-shell";
    };
    testExplicitSelectionOverridesEnvironment = {
      expr =
        (normalize {
          desktops = ["hyprland"];
          panels.active = "quickshell";
        }).panels.active;
      expected = "quickshell";
    };
    testExplicitNullDisablesPanel = {
      expr =
        (normalize {
          desktops = ["hyprland"];
          panels.active = null;
        }).panels.active;
      expected = null;
    };
    testUserSelectionOverridesHost = {
      expr =
        (mkUI {
          host.defaults.interface.panels.active = "dms-shell";
          user.interface.panels.active = "quickshell";
        }).panels.active;
      expected = "quickshell";
    };
    testPanelConfigurationSurvivesNormalisation = {
      expr =
        (normalize {
          desktops = ["hyprland"];
          panels.quickshell.package = "custom";
        }).panels;
      expected = {
        active = "dms-shell";
        quickshell.package = "custom";
      };
    };
    testSingularSelectorIsAbsent = {
      expr = (normalize {desktops = ["hyprland"];}) ? panel;
      expected = false;
    };
  };
in {
  total = length (attrNames tests);
  failures = lib.runTests tests;
}
