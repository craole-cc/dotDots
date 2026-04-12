{_, ...}: let
  meta = let
    doc = ''
      Application query builders (Layer 3).

      Provides composable query functions that partition an application set
      by field values, list membership, boolean flags, and field length.

      Includes semantic builders for well-known fields (maturity, protocol,
      scope, capability, config, independence, engine) and a standard query
      combinator that applies all of them in one call.

      Depends on: applications {groups, predicates, primitives, selection}.
    '';
    functions = {
      inherit mkBool;
    };
    exports = {
      local = functions;
      alias = {};
    };
  in {inherit doc exports functions;};

  inherit (_.applications.selection) withFlag withoutFlag;

  /**
  Partition an attribute set into two subsets based on the presence or absence
  of a boolean flag field, exposing them under caller-supplied keys.

  # Type
  ```nix
  mkBool :: {
    field    :: string,
    trueKey  :: string,
    falseKey :: string,
    set      :: AttrSet,
  } -> { ${trueKey} :: AttrSet, ${falseKey} :: AttrSet }
  ```

  # Examples
  ```nix
  mkBool {
    field    = "active";
    trueKey  = "running";
    falseKey = "stopped";
    set      = { a = { active = true; }; b = { active = false; }; };
  }
  # => { running = { a = { active = true;  }; };
  #      stopped = { b = { active = false; }; }; }
  ```
  */
  mkBool = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
