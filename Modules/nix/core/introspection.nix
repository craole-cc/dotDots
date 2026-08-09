{
  config,
  global ? {},
  lib,
  options,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.options) isOption;
  inherit (lib.types) anything unspecified;

  # ---- introspection surface ----
  # `config._` is the read-only introspection surface with three facets:
  #
  #   _ . schema — machine-readable metadata about every `${top}.inputs.*`
  #                option (default, type, description, declared?).
  #   _ . inputs  — the merged `${top}.inputs` tree, declared by the modules
  #                themselves and round-trippable by every module writer.
  #   _ . output  — the *intended* config output that modules explicitly stage
  #                for writing.  Each module that sets NixOS `config` also
  #                sends a copy of its attrset to `${top}.output` so the
  #                staged tree accumulates through the normal module-system
  #                merge.  This is NOT a diff of the evaluated config — it is
  #                a declaration of intent, staged before actual evaluation.
  #
  # `schema` and `output` are per-host.  Global settings (names, paths, etc.)
  # are constructed at the flake/API-global tier and copied into each host's
  # schema for discovery; this module does not construct or evaluate them.

  inputsOptions = options._.inputs or {};

  # ---- schema ----
  # Walk the `${top}.inputs` option tree and emit per-leaf metadata.
  # Functions/thunks in option defaults are surfaced as `__function`.

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

  # Global is copied into the per-host schema for discovery only.  It remains
  # constructed at the flake/API-global tier, never by this host module.
  schemaTree = {inherit global;} // walkMetadata inputsOptions;

in {
  options._ = {
    schema = lib.mkOption {
      description = "Machine-readable dots option surface and declared defaults";
      default = {};
      type = anything;
    };
    # `output` is declared here but populated by every module that writes
    # config.  Modules add `config.${top}.output.<path> = value` alongside
    # their normal `config` assignments; the module system merges those into
    # the final staged tree.
    output = lib.mkOption {
      description = "Staged config output intended for writing (not evaluated config)";
      default = {};
      # `unspecified` delegates to the module system's built-in merge: attrsets
      # merge recursively and lists concatenate, so multiple modules can stage
      # the same top-level key (e.g. `assertions`, `swapDevices`) without
      # conflict.  This is a staging area, not a typed schema.
      type = unspecified;
    };
  };

  config._.schema = schemaTree;
  # `config._.output` is NOT set here.  Modules write their staged output to
  # `config.${top}.output.<path> = value`; since `top = "_"`, those flow
  # through the declared `options._.output` and merge automatically.
}
