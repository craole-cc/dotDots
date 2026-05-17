{
  _,
  lib,
  ...
}: let
  meta = let
    doc = ''
      # Style - Opacity

      Resolver and types for opacity configuration.

      ## Functions

      - `resolve` - builds a `{ light, dark }` opacity attrset from base
                    values and per-polarity overrides

      ## Types

      - `types.core` - NixOS submodule: `{ terminal, popups }`
      - `types.home` - home-manager submodule: `{ terminal, popups }`
    '';
    exports = {
      local = {inherit resolve types;};
      alias = {resolveOpacity = resolve;};
    };
  in {inherit doc exports;};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.options) mkOption;
  inherit (lib.types) float submodule;

  types = let
    common = submodule {
      options = {
        terminal = mkOption {
          description = "Terminal background opacity (0.0-1.0)";
          type = float;
        };
        popups = mkOption {
          description = "Popup/overlay background opacity (0.0-1.0)";
          type = float;
        };
      };
    };
  in {
    core = type;
    home = type;
  };

  resolve = {
    light ? {},
    dark ? {},
  }: let
    base = {
      terminal = 0.9;
      popups = 0.95;
    };
  in
    recursiveUpdate {
      light = base;
      dark = base;
    } {inherit light dark;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
