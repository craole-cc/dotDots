{
  config,
  global ? {},
  lib,
  options,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs removeAttrs;
  inherit (lib.options) isOption;
  inherit (lib.types) anything;

  # ---- introspection surface (Part A item 1) ----
  # `schema` contains per-option metadata, `inputs` is the merged
  # `${top}.inputs` tree declared by the modules themselves, and `output` is
  # the evaluated config diffed against raw option defaults.
  #
  # `config._` is the read-only introspection surface.  `${top}.inputs.*` is
  # where modules declare their own options, so introspection must NOT declare
  # `_.inputs` itself (it would clash with the nested module options).  This
  # module declares only the projections `_.schema` and `_.output`; `_.inputs`
  # is exposed purely as a pass-through of the merged module option tree.

  inputsOptions = options._.inputs or {};

  # ---- schema ----
  # Walk the `${top}.inputs` option tree and emit per-leaf metadata.  Functions
  # and thunks in option defaults are surfaced as `__function` rather than
  # forcing a non-serializable value.

  isFunction = v:
    builtins.isFunction v
    || (builtins.isAttrs v && (v ? __functor || v ? __function));

  optionMetadata = option: {
    __dotsOption = true;
    declared = option ? default;
    value =
      if option ? default
      then
        if isFunction option.default
        then "__function"
        else option.default
      else null;
    description = option.description or null;
    type = option.type.name or null;
  };

  walkMetadata = node:
    if isOption node
    then optionMetadata node
    else mapAttrs (_: walkMetadata) node;

  # API global values are plain serializable declarations, intentionally kept
  # beside the per-host `${top}.inputs` metadata for discovery.
  schemaTree = {inherit global;} // walkMetadata inputsOptions;

  # ---- output — Part A item 2 ----
  # `output` is a genuine diff of the evaluated system config against raw NixOS
  # *option defaults* (lib.mkDefault priority), not the full tree.
  #
  # The previous implementation returned the whole evaluated `config` because a
  # naive recursive diff against `options` (including NixOS internals) stack-
  # overflowed.  Root cause: unbounded recursion into non-serializable /
  # self-referential values (functions, thunks, lazy option thunks) — the tree
  # is not actually infinitely deep.
  #
  # Fix (per spec):
  #   • Skip functions/thunks during the walk instead of recursing.
  #   • Cap recursion depth (maxDepth) as a safety net.
  #   • Diff `home-manager.users.*` as its own explicitly-recursed branch so the
  #     generic walk never hits the deeply-nested HM option internals.

  maxDepth = 40;

  # Ω-like equality: never throw, never infinite-loop.
  safeEqual = left: right: let
    checked = builtins.tryEval (left == right);
  in
    checked.success && checked.value;

  # Is the NixOS `option` record itself (or its default) a function/thunk?
  optionIsFunction = option:
    option ? default && isFunction option.default;

  # Diff `current` (config side) against `option` (options side).  A leaf is
  # present iff its value differs from the option's default.  Internal nodes
  # recurse, skipping function-typed option defaults.
  diffNode = depth: current: option:
    if depth > maxDepth
    then {present = false; value = null;}
    else if isFunction current
    then {present = false; value = null;} # non-serializable config value
    else if isOption option
    then {
      present =
        !(option ? default
          && safeEqual current option.default);
      value = current;
    }
    else if optionIsFunction option
    then {present = false; value = null;} # non-serializable skip
    else
      let
        declared =
          filterAttrs
          (name: _: current ? ${name})
          (mapAttrs
            (name: opt: diffNode (depth + 1) current.${name} opt)
            option);
        undeclared =
          mapAttrs
          (_: value: {present = true; inherit value;})
          (removeAttrs current (builtins.attrNames option));
        entries = filterAttrs (_: result: result.present) (declared // undeclared);
      in {
        present = entries != {};
        value = mapAttrs (_: result: result.value) entries;
      };

  diffOptions = removeAttrs options ["_" "_module"];
  diffConfig  = removeAttrs config  ["_" "_module"];

  # Generic diff of the system config tree (.value unwraps the {present,value}
  # marker the internal diffNode helper returns).
  systemDiff = (diffNode 0 diffConfig diffOptions).value;

  # `home-manager.users.*` as its own branch so the walk into HM internals is
  # depth-bounded from the user stem, not from the config root.
  homeManagerDiff =
    if !(diffConfig ? home-manager && diffConfig.home-manager ? users)
    then {}
    else {
      home-manager = diffConfig.home-manager // {
        users =
          mapAttrs
          (name: userConfig:
            if diffOptions ? home-manager
               && diffOptions.home-manager ? users
               && diffOptions.home-manager.users ? ${name}
            then (diffNode 0 userConfig diffOptions.home-manager.users.${name}).value
            else userConfig)
          diffConfig.home-manager.users;
      };
    };

  outputTree = systemDiff // homeManagerDiff;

in {
  options._ = {
    schema = lib.mkOption {
      description = "Machine-readable dots option surface and declared defaults";
      default = {};
      type = anything;
    };
    output = lib.mkOption {
      description = "Evaluated NixOS and Home Manager changes against raw option defaults";
      default = {};
      type = lib.types.raw;
    };
  };

  config._.schema = schemaTree;
  config._.output = outputTree;
}
