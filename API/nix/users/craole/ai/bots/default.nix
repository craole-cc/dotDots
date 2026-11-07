{
  lix,
  homeDirectory,
  homePath,
  definitions,
  enabled,
}: let
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.lists.selection) filter;
  inherit (lix.lists.predicates) elem;
  load = name: import definitions.${name} {inherit lix homeDirectory homePath;};
  root = load "hermes";
in
  assert elem "hermes" enabled;
    root
    // {
      profiles =
        genAttrs (filter (name: name != "hermes") enabled) (name:
          {bot.enable = true;} // load name);
    }
