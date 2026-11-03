{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.lists.access) length;
  root = ../../Modules/nix/home/interface/panels/dank-material-shell;
  defaults = import (root + "/defaults") {inherit lix;};
  toOutput = import (root + "/settings-output.nix") {inherit lix;};
  output = toOutput defaults.settings;
  custom = toOutput {
    theme.name = "custom";
    calendar.backend = "dankcal";
    battery.charge.limit = 80;
    notifications.fonts.body.size = 14;
    hyprland.groups.bar.text.padding = 3;
    clipboard = {
      paste.click = false;
      history.maxItems = 200;
    };
  };
  tests = {
    testAllDefaultValuesPreserveUpstreamContract = {
      expr = builtins.hashString "sha256" (builtins.toJSON output.settings);
      expected = "6b40b568df4c49763bc924552ecb039073cb5b325030eb32629175e4c6fe4db8";
    };
    testNestedOverridesTranslateToUpstreamNames = {
      expr = custom.settings;
      expected = {
        currentThemeName = "custom";
        calendarBackend = "dankcal";
        batteryChargeLimit = 80;
        notificationBodyFontSize = 14;
        hyprlandGroupbarTextPadding = 3;
        clipboardClickToPaste = false;
      };
    };
    testClipboardHistoryUsesSeparateOutput = {
      expr = custom.clipboardSettings;
      expected.maxItems = 200;
    };
    testClipboardHistoryIsExcludedFromMainSettings = {
      expr = custom.settings ? clipboard;
      expected = false;
    };
    testUnknownSettingsFail = {
      expr = (builtins.tryEval (builtins.deepSeq (toOutput {battery.unknown = true;}) true)).success;
      expected = false;
    };
    testScalarGroupFails = {
      expr = (builtins.tryEval (builtins.deepSeq (toOutput {battery = false;}) true)).success;
      expected = false;
    };
    testEmptyOverridesRemainEmpty = {
      expr = toOutput {};
      expected = {
        settings = {};
        clipboardSettings = {};
      };
    };
    testClockDefaultsUseGroupedSchema = {
      expr = defaults.settings.clock;
      expected = {
        format = "24h";
        seconds = true;
        week.number = true;
      };
    };
  };
in {
  total = length (attrNames tests);
  failures = lib.runTests tests;
}
