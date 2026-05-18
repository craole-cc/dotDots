{_, ...}: let
  meta = let
    doc = ''
      Style types (Layer 1).

      Reusable NixOS/home-manager submodule types for all style domains.
      Each domain exposes `core` and `home` variants.

      ## Types

      - `icons.core`   / `icons.home`   - { name, package }
      - `cursors.core` / `cursors.home` - { name, package, size }
      - `opacity.core` / `opacity.home` - { terminal, popups }
    '';
    exports = {
      local = {inherit icons cursors opacity;};
      alias = {
        iconType = icons;
        cursorType = cursors;
        opacityType = opacity;
      };
    };
  in {inherit doc exports;};

  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) nullOr submodule;
  inherit (_.types.primitives) float int package str;

  icons = let
    common = submodule {
      options = {
        name = mkOption {
          description = "Icon theme canonical registry key";
          type = nullOr str;
          default = null;
        };
        package = mkOption {
          description = "Icon theme package";
          type = nullOr package;
          default = null;
        };
      };
    };
  in {
    core = common;
    home = common;
  };

  cursors = let
    common = submodule {
      options = {
        name = mkOption {
          description = "Cursor theme name";
          type = nullOr str;
          default = null;
        };
        package = mkOption {
          description = "Cursor theme package";
          type = nullOr package;
          default = null;
        };
        size = mkOption {
          description = "Cursor size in pixels";
          type = int;
          default = 24;
        };
      };
    };
  in {
    core = common;
    home = common;
  };

  opacity = let
    common = submodule {
      options = {
        terminal = mkOption {
          description = "Terminal background opacity (0.0-1.0)";
          default = 0.9;
          type = float;
        };
        popups = mkOption {
          description = "Popup/overlay background opacity (0.0-1.0)";
          default = 0.95;
          type = float;
        };
      };
    };
  in {
    core = common;
    home = common;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
