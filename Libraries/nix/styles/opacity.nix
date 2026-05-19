{_, ...}: let
  meta = let
    doc = ''
      Opacity resolution (Layer 3).

      Resolves terminal and popup opacity for light and dark modes.
      Per-mode overrides are merged over shared defaults via recursiveUpdate.

      Depends on: attrsets.
    '';
    exports = {
      local = {inherit opacity;};
      alias = {};
    };
  in {inherit doc exports;};

  inherit (_.attrsets) recursiveUpdate;

  # ── Resolve ───────────────────────────────────────────────────────────────

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
