{lix, ...}: let
  inherit (lix.attrsets) attrNames genAttrs isAttrs;
  inherit (lix.lists) filter isList unique;
  inherit (lix.debug) requireThat;
  inherit (lix.inputs) dotDots;
  inherit (lix.strings) mkPath;
  inherit (lix.trivial) pathExists typeOf;

  registry = let
    canonical = mkPath dotDots.path [
      "Libraries"
      "nix"
      "lists"
      "enums"
      "data"
      "functionalities.nix"
    ];

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

    names =
      if pathExists canonical
      then import canonical
      else fallback;
    values = genAttrs names (_: {});
  in {inherit names values;};

  #? Functionalities are declared either as a list of names or as an attrset of
  #? names to `{}`. Both are first-class: the shape is preserved on `values`,
  #? and `names` gives the list view of either, so a consumer picks its shape
  #? instead of the host author having to care.
  default = [];

  getNames = value:
    if value == null
    then []
    else if isList value
    then unique value
    else if isAttrs value
    then unique (attrNames value)
    else throw "resolve host functionalities: expected a list of names or an attrset, but got ${typeOf value}";

  #? The declared shape, untouched. `values` is what the host wrote;
  #? `values.names` is the list view; `values.set` is the attrset view.
  #? Round-tripping a host through resolve is lossless either way.
  asSet = value: genAttrs (getNames value) (_: {});

  resolve = args: let
    declared = args.functionalities or default;
    resolvedNames = getNames declared;
    unknown = filter (name: !(registry.values ? ${name})) resolvedNames;
    context = "resolve host functionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = ''
        unknown functionalities: ${toString unknown}
        known: ${toString registry.names}
      '';
    }; {
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
      known = registry.names;
    };

  deriveFunctionalities = {
    default,
    defined,
  }: let
    args = defined.functionalities or {};
    names = unique args;
    unknown =
      filter
      (name: !(default.functionalities ? ${name}))
      names;
    context = "deriveFunctionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown functionalities: ${toString unknown}";
    }; names;
in {inherit asSet default deriveFunctionalities getNames registry resolve;}
