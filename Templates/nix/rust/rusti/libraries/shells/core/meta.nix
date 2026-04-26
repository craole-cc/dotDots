{lib}: let
  inherit (lib.attrsets) attrNames filterAttrs listToAttrs optionalAttrs;
  inherit (lib.lists) elem foldl' isList;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) functionArgs;

  callNamespace = ns: args: let
    declared = attrNames (functionArgs ns.mkShell);
    filtered = filterAttrs (n: _: elem n declared) args;
  in
    ns.mkShell filtered;

  /**
  Empty shell-spec baseline used by merge helpers.

  # Type
  ```nix
  emptySpec :: AttrSet
  ```

  # Examples
  ```nix
  emptySpec
  # => {
  #   __meta = {};
  #   shell = {
  #     name = "unnamed";
  #     packages = [];
  #     env = {};
  #     shellHook = "";
  #   };
  # }
  ```

  # Returns
  The neutral shell spec used as the baseline for shell merges.
  */
  emptySpec = {
    __meta = {};
    shell = {
      name = "unnamed";
      packages = [];
      env = {};
      shellHook = "";
    };
  };

  mergeSpecs = namespaces: let
    # Accept list (ordered) or attrset (keys become labels)
    ns =
      if isList namespaces
      then
        listToAttrs (map (n: {
            name = n.__meta.kind or "?";
            value = n;
          })
          namespaces)
      else namespaces;

    names = attrNames ns;
    kind = concatStringsSep "+" names;

    mkShell = args: let
      parts = map (n: callNamespace ns.${n} args) names;
      partNames = map (n: (callNamespace ns.${n} args).shell.name or n) names;
      merged = foldl' mergeSpecs emptySpec parts;
    in
      merged
      // {
        __meta = merged.__meta // {inherit kind;};
        shell = merged.shell // {name = concatStringsSep "+" partNames;};
      };

    mkSuite = {pkgs ? null}: let
      subSuites = map (n:
        optionalAttrs
        (ns.${n} ? mkSuite)
        ns.${n}.mkSuite {inherit pkgs;})
      names;
    in
      foldl' (acc: s: acc // s) {} subSuites;
  in {
    inherit mkShell mkSuite;
    mkShells = mkSuite;
  };
in {
  inherit emptySpec mergeSpecs;
}
