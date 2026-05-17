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
        iconType   = icons;
        cursorType = cursors;
        opacityType = opacity;
      };
    };
  in {inherit doc exports;};

  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) submodule;
  inherit (_.types.primitives) float int package str;

  iconSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Icon theme canonical registry key";
        type = str;
      };
      package = mkOption {
        description = "Icon theme package";
        type = package;
      };
    };
  };

  cursorSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Cursor theme name";
        type = str;
      };
      package = mkOption {
        description = "Cursor theme package";
        type = package;
      };
      size = mkOption {
        description = "Cursor size in pixels";
        type = int;
        default = 24;
      };
    };
  };

  opacitySubmodule = submodule {
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

  icons   = {core = iconSubmodule;   home = iconSubmodule;};
  cursors = {core = cursorSubmodule; home = cursorSubmodule;};
  opacity = {core = opacitySubmodule; home = opacitySubmodule;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
