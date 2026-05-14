/**
libraries/filesystem/imports.nix

Import helpers built on top of filesystem path discovery.
*/
{lib}: let
  inherit (lib) assemble;
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    filterAttrs
    mergeAttrsList
    ;
  inherit (lib.filesystem) isPath collectPaths;
  inherit (lib.lists) elem map isList;
  inherit (lib.strings) removeSuffix;
  inherit (lib.trivial) functionArgs isFunction;

  /**
  Normalize filesystem import input into a uniform attrset.

  Supported inputs are a single path, a list of paths, or an attrset carrying
  explicit options.

  # Type
  ```nix
  normalizeInput :: AttrSet -> path | [path] | AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  normalizeInput {} ./tests/fixtures/filesystem/plain
  # => {
  #   recurse = false;
  #   namespace = null;
  #   args = {};
  #   priority = [];
  #   ignore = [];
  #   path = ./tests/fixtures/filesystem/plain;
  # }
  ```

  # Returns
  A normalized option attrset suitable for the other import helpers.
  */
  normalizeInput = defaults: input: let
    base =
      {
        recurse = false;
        namespace = null;
        args = {};
        priority = [];
        ignore = [];
      }
      // defaults;
  in
    if isPath input
    then base // {path = input;}
    else if isList input
    then base // {path = input;}
    else base // input;

  /**
  Infer a namespace name from a file or directory path.

  Files lose the trailing `.nix` suffix; directories keep their basename.

  # Type
  ```nix
  inferNamespace :: path -> string
  ```

  # Examples
  ```nix
  inferNamespace ./demo.nix
  # => "demo"

  inferNamespace ./libraries/strings
  # => "strings"
  ```

  # Returns
  The namespace name inferred from the path basename.
  */
  inferNamespace = path: removeSuffix ".nix" (baseNameOf (toString path));

  /**
  Import a path and pass only the function arguments it declares.

  This keeps library imports tolerant of wider argument sets.

  # Type
  ```nix
  importWithFilteredArgs :: path -> AttrSet -> any
  ```

  # Examples
  ```nix
  importWithFilteredArgs ./tests/fixtures/filesystem/attrs/alpha.nix {
    value = 9;
    ignored = true;
  }
  # => { alpha = 9; }
  ```

  # Returns
  The imported value, with undeclared function arguments stripped before application.
  */
  importWithFilteredArgs = path: args: let
    target = import path;
  in
    if isFunction target
    then let
      declared = attrNames (functionArgs target);
      filtered = filterAttrs (name: _: elem name declared) args;
    in
      target filtered
    else target;

  /**
  Resolve importable paths from normalized filesystem input.

  # Type
  ```nix
  importPaths :: path | [path] | AttrSet -> [path]
  ```

  # Examples
  ```nix
  importPaths {
    path = ./tests/fixtures/filesystem/nested;
    recurse = true;
    ignore = ["deep"];
  }
  # => [
  #   ./tests/fixtures/filesystem/nested/root.nix
  #   ./tests/fixtures/filesystem/nested/has-default
  # ]
  ```

  # Returns
  The list of importable Nix paths resolved from the given input.
  */
  importPaths = input: let
    n = normalizeInput {} input;
  in
    collectPaths {inherit (n) path recurse ignore;};

  /**
  Import multiple attrset fragments and expose aggregate metadata.

  Imported values are merged with `mergeAttrsList`. Metadata is returned under
  `__meta`.

  # Type
  ```nix
  importAttrs :: path | [path] | AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  importAttrs {
    path = ./tests/fixtures/filesystem/attrs;
    args = { value = 9; };
  }
  # => {
  #   __meta = { ... };
  #   alpha = 9;
  #   beta = "ok";
  # }
  ```

  # Returns
  A merged attrset of imported values plus aggregate metadata under `__meta`.
  */
  importAttrs = input: let
    n = normalizeInput {} input;
    paths = collectPaths {inherit (n) path recurse ignore;};
    all = mergeAttrsList (map (p: importWithFilteredArgs p n.args) paths);
    names = attrNames all;
    values = attrValues all;
  in
    {__meta = {inherit names values all;};} // all;

  /**
  Import library leaf files and mount them under a namespace.

  Entries are assembled sequentially so later members can depend on earlier
  members in the same namespace.

  # Type
  ```nix
  importLibs :: path | [path] | AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  importLibs ./tests/fixtures/filesystem/libs
  # => {
  #   libs = {
  #     base = 1;
  #     derived = 2;
  #   };
  #   __meta.libs = { ... };
  # }
  ```

  # Returns
  An attrset containing the mounted namespace and namespace metadata.
  */
  importLibs = input: let
    n = normalizeInput {args = {};} input;
    paths = collectPaths {inherit (n) path recurse ignore;};
    namespace =
      if n.namespace != null
      then n.namespace
      else inferNamespace n.path;

    all = assemble {
      start = {};
      entries = paths;
      scope = acc: lib // {${namespace} = acc;};
      priority = n.priority or [];
      ignore = n.ignore or [];
      dependencies = n.dependencies or [];
    };

    names = attrNames all;
    values = attrValues all;
  in {
    ${namespace} = all;
    __meta.${namespace} = {
      inherit
        namespace
        names
        values
        all
        paths
        ;
    };
  };
in {
  inherit
    importPaths
    importAttrs
    importLibs
    normalizeInput
    inferNamespace
    ;
  imports = importPaths;
}
