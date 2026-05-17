{_, ...}: let
  meta = let
    doc = ''
      # Style - Registry

      Aggregates pure data registries from each style domain.
      Each domain owns its data; this provides a single access point.

      ## Registries

      - `icons`   - icon theme entries
      - `cursors` - cursor theme entries (TODO)
      - `fonts`   - font entries (TODO)
    '';
    exports = {
      local = {
        inherit icons;
      };
      alias = {
        iconRegistry = icons;
      };
    };
  in {inherit doc exports;};

  icons = _.style.icons.registry;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
