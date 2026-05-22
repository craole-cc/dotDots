{_, ...}: let
  meta = let
    doc = ''
      Source registry predicates (Layer 0).

      Provides primitive predicates for inspecting registry trees before
      higher-level construction and resolution run. Currently exports
      `hasCategories`, a boolean predicate that detects whether an attrset
      looks like a registry leaf by checking that its first value is an
      attrset containing a `categories` field.

      Depends on: attrsets.access, content.emptiness, lists.access,
      types.predicates.
    '';

    exports = let
      internal = let
        functions = {inherit hasCategories;};
        aliases = {isRegistry = hasCategories;};
      in
        {inherit functions aliases;} // functions // aliases;
      external = {
        isRegistryAttrs = hasCategories;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrValues;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.lists.access) head;
  inherit (_.types.predicates) isAttrs;

  /**
      Return `true` when `tree` is a non-empty attribute set whose first value
      looks like a registry entry (i.e. is an attrset containing `categories`).

      Used to distinguish leaf registry sets from intermediate grouping nodes
      during recursive enum construction.

      # Type
  ```nix
      hasCategories :: AttrSet -> bool
  ```

      # Examples
  ```nix
      hasCategories { bash = { categories = [ "shell" ]; }; }
      # => true

      # Intermediate grouping node - values are not registry entries
      hasCategories { system = { bash = { categories = [ "shell" ]; }; }; }
      # => false

      hasCategories {}
      # => false
  ```
  */
  hasCategories = raw:
    (isNotEmpty raw)
    && (
      let
        fields = head (attrValues raw);
      in
        isAttrs fields && fields ? categories
    );
in
  with meta.exports;
    internal
    // {
      __docs = meta.doc;
      __rootAliases = external;
    }
