{_, ...}: let
  meta = let
    doc = ''
      Opacity resolution (Layer 3).

      Resolves terminal and popup opacity for light and dark modes.
      Per-mode overrides are merged over shared defaults via recursiveUpdate.

      Depends on: attrsets.
    '';
    exports = {
      local = {inherit opacity types;};
      alias = {};
    };
  in {inherit doc exports;};

  inherit (_.attrsets) recursiveUpdate;
  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) nullOr submodule;
  inherit (_.types.primitives) float;

  types = let
    common = submodule {
      options = {
        terminal = mkOption {
          description = "Terminal background opacity (0.0-1.0)";
          type = float;
          default = 0.9;
        };
        popups = mkOption {
          description = "Popup/overlay background opacity (0.0-1.0)";
          type = float;
          default = 0.95;
        };
      };
    };
  in {
    opacity = {
      core = common;
      home = common;
    };
  };

  opacity = {
    terminal ? 0.9,
    popups ? 0.95,
    light ? {},
    dark ? {},
  }:
    recursiveUpdate
    {
      light = {inherit terminal popups;};
      dark = {inherit terminal popups;};
    }
    {inherit light dark;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
