{_, ...}: let
  meta = let
    doc = ''
      Compatibility aggregate for style types.

      Canonical type definitions live with each style module:
      - `styles.icons.types.icon`
      - `styles.cursors.types.polarity`
      - `styles.themes.types.theme`
      - `styles.opacity.types.opacity`

      This entrypoint exists only for older consumers.
    '';
    exports = {
      local = {
        inherit (_.styles.icons.types) icon;
        inherit (_.styles.cursors.types) polarity;
        inherit (_.styles.themes.types) theme;
        inherit (_.styles.opacity.types) opacity;
      };
      alias = {};
    };
  in {inherit doc exports;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
