{_, ...}: let
  meta = let
    doc = ''
      opacity - resolves terminal and popup opacity values for light and dark modes.
      Accepts per-mode overrides; falls back to shared defaults.
    '';
    exports = {
      local = {inherit opacity;};
      alias = {};
    };
  in {inherit doc exports;};

  inherit (_.attrsets) recursiveUpdate;

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
