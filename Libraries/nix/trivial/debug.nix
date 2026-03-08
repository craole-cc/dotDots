{lib, ...}: let
  inherit (lib.strings) concatStringsSep;

  /**
    Create a set of debug helpers bound to a module's namespace path.

    # Usage
  ```nix
    {_, __moduleNamespacePath, ...}: let
      debug = _.trivial.debug.mkModuleDebug __moduleNamespacePath;
    in {
      myFn = value:
        if badCondition
        then debug.throw "myFn" "something went wrong"
        else ...;
    }
  ```
  */
  mkModuleDebug = namespacePath: let
    namespace = concatStringsSep "." namespacePath;
  in {
    #? Generate error with location
    throwWithLoc = fnName: msg:
      throw "${namespace}.${fnName}: ${msg}";

    #> Generate error with location and doc string appended
    throwWithDoc = fnName: msg: doc:
      throw "${namespace}.${fnName}: ${msg}\n\nDocumentation:\n${doc}";

    #> Format the error string without throwing, useful for trace
    mkError = fnName: msg: "${namespace}.${fnName}: ${msg}";
  };

  exports = {inherit mkModuleDebug;};
in
  exports // {_rootAliases = exports;}
