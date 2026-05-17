{_, ...}: let
  meta = let
    doc = ''
      # Style Types

      Reusable NixOS option types for style/visual configuration.

      ## Types

      - `opacity.core`  - submodule for NixOS-layer opacity config (terminal, popups)
      - `opacity.home`  - submodule for home-manager-layer opacity config (terminal, popups)

    '';
    exports = {
      local = {inherit opacity;};
      alias = {opacityType = opacity;};
    };
  in {inherit doc exports;};
  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) submodule;
  inherit (_.types.primitives) float;

  opacity = let
    default = submodule {
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
    core = default;
    home = default;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
