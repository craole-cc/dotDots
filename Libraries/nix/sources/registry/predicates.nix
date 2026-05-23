{_, ...}: let
  meta = let
    doc = ''
      Source registry predicates.

      Provides small, reusable checks for deciding whether an attrset looks
      like a registry tree. The predicate is generic: it only checks that the
      tree is non-empty and that the first value is itself an attrset.

      Depends on: attrsets.access, content.emptiness, types.predicates.
    '';

    exports = let
      internal = let
        functions = {inherit isRegistry;};
        aliases = {
          isRegistryTree = isRegistry;
          isRegistryAttrs = isRegistry;
        };
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        isRegistryAttrs = isRegistry;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrValues;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.lists.access) head;
  inherit (_.types.predicates) isAttrs;

  /**
    Return `true` when `tree` is a non-empty attrset whose first value is
    itself an attrset.

    This is intentionally loose: registry consumers can apply stronger domain
    rules on top (for example checking for `categories`, `name`, or `value`).

    # Type
    ```nix
    isRegistry :: AttrSet -> bool
    ```
  */
  isRegistry = tree:
    isAttrs tree
    && isNotEmpty tree
    && isAttrs (head (attrValues tree));
in
  with meta.exports;
    internal
    // {
      __docs = meta.doc;
      __rootAliases = external;
    }
