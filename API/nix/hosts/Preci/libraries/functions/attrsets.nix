{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldl' reverseList;

  mkMergedAttrs = args: let
    defaults = args.declared or args.default;
    overrides = args.declared or args.overrides;
  in {
    inherit defaults overrides;
    merged =
      foldl'
      recursiveUpdate
      defaults
      (reverseList overrides);
  };
in {inherit mkMergedAttrs;}
