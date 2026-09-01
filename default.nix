{...} @ args: let
  utils = rec {
    inherit
      (builtins)
      attrNames
      elem
      foldl'
      isAttrs
      listToAttrs
      stringLength
      substring
      ;

    unique = foldl' (acc: x:
      if elem x acc
      then acc
      else acc ++ [x]) [];

    mergeAttrsRecursive = set1: set2:
      if isAttrs set1 && isAttrs set2
      then let
        keys = unique (attrNames set1 ++ attrNames set2);
      in
        listToAttrs (
          map (key: {
            name = key;
            value =
              if set1 ? ${key} && set2 ? ${key}
              then mergeAttrsRecursive set1.${key} set2.${key}
              else set2.${key} or set1.${key};
          })
          keys
        )
      else set2;
  };
  inherit (utils) mergeAttrsRecursive;

  paths = mergeAttrsRecursive {
    core = {
      src.store = ./.;
      api.default.store = ./API/nix;
      lib.default.store = ./Libraries/nix;
    };
  } (args.paths or {});
  inherit (paths.core.lib.default) store;

  init = {
    args = mergeAttrsRecursive args {inherit utils paths;};
    lib = import store init.args;
  };
  _ = init.lib.libraries.default;

  eval = {
    args = mergeAttrsRecursive init.args {
      schema = _.schema.construction.mkSchema init.args;
    };
    lib = import store eval.args;
  };
in
  eval.lib
