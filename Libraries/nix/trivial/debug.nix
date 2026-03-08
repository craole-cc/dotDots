{lib, ...}: let
  inherit (lib.strings) concatStringsSep;

  #~@ Namespace Utilities
  /**
  Convert a namespace path list to a dotted string.
  */
  mkNamespace = namespacePath:
    concatStringsSep "." namespacePath;

  /**
  Create a fully qualified reference to a function.
  */
  mkRef = name: namespacePath: fnName: "${name}.${mkNamespace namespacePath}.${fnName}";

  /**
  Create a usage hint string pointing to :doc for full reference.
  */
  mkUsage = name: namespacePath: fnName: typeSignature: "Usage:\n  ${typeSignature}\n  repl> :doc ${mkRef name namespacePath fnName}";

  #~@ Error Utilities
  /**
    Create a set of debug helpers bound to a module's namespace path.

    # Usage
  ```nix
    {_, name, __moduleNamespacePath, ...}: let
      debug = _.trivial.debug.mkModuleDebug name __moduleNamespacePath;
    in {
      myFn = value:
        if badCondition
        then debug.throw "myFn" "something went wrong"
        else ...;
    }
  ```
  */
  mkModuleDebug = name: namespacePath: let
    ref = mkRef name namespacePath;
    usage = mkUsage name namespacePath;
  in {
    #? Throw with just location
    throw = fnName: msg:
      throw "${ref fnName}: ${msg}";

    #> Throw with location and usage hint appended
    throwWithUsage = fnName: msg: typeSignature:
      throw "${ref fnName}: ${msg}\n\n${usage fnName typeSignature}";

    #> Format error string without throwing, useful for trace
    mkError = fnName: msg: "${ref fnName}: ${msg}";

    #> Expose ref and usage for manual use
    inherit ref usage;
  };

  exports = {
    inherit
      mkNamespace
      mkRef
      mkUsage
      mkModuleDebug
      ;
  };
in
  exports // {_rootAliases = exports;}
