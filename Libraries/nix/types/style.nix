{
  _,
  ...
}: let
  meta = let
    doc = ''
    '';
    exports = {
      local = {inherit opacity;};
      alias = {opacityType = opacity;};
    };
  in {inherit doc exports;};
  inherit (_.types.combinators) submodule;

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
in{
  core = default;
  home = default;
};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
