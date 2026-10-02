{
  lib,
  lix,
  sources ? null,
  ...
}: let
  inherit (lib.attrsets) attrNames genAttrs isAttrs;
  inherit (lib.lists) filter isList unique;
  inherit (lix.debug) requireThat;

  #? The vocabulary lives in a pure data leaf under `Libraries`, which both
  #? this tree and the legacy `_` tree can import. `Libraries`'s own
  #? `enums/hardware.nix` is a `{_, ...}` module and cannot be evaluated
  #? without bootstrapping the entire module system, so the names are kept in
  #? a file that takes no arguments and imports nothing.
  #?
  #? `sources` is the dotDots repository root, threaded in by the caller. When
  #? it is null (the schema is being used outside a host checkout) the
  #? vocabulary falls back to the built-in set below, so evaluation never
  #? fails for lack of a path.
  vocabulary =
    if sources == null
    then null
    else import (sources + "/Libraries/nix/lists/enums/data/functionalities.nix");

  #? The fallback set. Every name the repository's hosts declare, and nothing
  #? else. It exists so a checkout-less evaluation still validates; it is not
  #? the source of truth and drifts upward only, never downward.
  fallback = [
    "audio"
    "battery"
    "bluetooth"
    "control-plane"
    "efi"
    "gpu"
    "keyboard"
    "network"
    "nvme"
    "secureboot"
    "storage"
    "touchpad"
    "tpm"
    "video"
    "virtualization"
    "vpn"
    "webcam"
    "wired"
    "wireless"
  ];

  allowed =
    if vocabulary == null
    then fallback
    else vocabulary;

  allowedSet = genAttrs allowed (_: {});

  #? Functionalities are declared either as a list of names or as an attrset of
  #? names to `{}`. Both are first-class: the shape is preserved on `values`,
  #? and `names` gives the list view of either, so a consumer picks its shape
  #? instead of the host author having to care.
  default = [];

  names = value:
    if value == null
    then []
    else if isList value
    then unique value
    else if isAttrs value
    then unique (attrNames value)
    else
      throw "resolve host functionalities: expected a list of names or an attrset, but got ${builtins.typeOf value}";

  #? The declared shape, untouched. `values` is what the host wrote;
  #? `values.names` is the list view; `values.set` is the attrset view.
  #? Round-tripping a host through resolve is lossless either way.
  asSet = value: genAttrs (names value) (_: {});

  resolve = {args ? {}}: let
    declared = args.functionalities or default;
    resolvedNames = names declared;
    unknown = filter (name: !(allowedSet ? ${name})) resolvedNames;
    context = "resolve host functionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = ''
        unknown functionalities: ${toString unknown}
        known: ${toString allowed}
      '';
    };
    {
      #? The list view, and the attrset view. Both are derived, both are
      #? stable; the host's own shape is recorded in `isList`.
      #?
      #? `names` is bound explicitly rather than inherited: the outer `names`
      #? is the shape-reading function, and an `inherit` would shadow the
      #? resolved list with that function.
      names = resolvedNames;
      set = asSet declared;
      isList = isList declared;
      values =
        if isList declared
        then resolvedNames
        else asSet declared;
      known = allowed;
    };
in {
  inherit default resolve names asSet allowed;
  isList = isList;
  isAttrs = isAttrs;
}
