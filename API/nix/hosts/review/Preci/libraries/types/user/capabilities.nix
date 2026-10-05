{lix, ...}: let
  inherit (lix.attrsets) attrNames isAttrs recursiveUpdate;
  inherit (lix.lists) filter foldl' isList unique;
  inherit (lix.debug) requireThat;
  inherit (lix.inputs) dotDots;
  inherit (lix.strings) mkPath;
  inherit (lix.trivial) pathExists typeOf;

  registry = let
    #? The vocabulary lives in a pure data leaf under `Libraries`, for the
    #? same reason as `host/functionalities.nix`: the legacy enum is a
    #? `{_, ...}` module and cannot be read from outside its own tree.
    canonical = mkPath dotDots.path [
      "Libraries"
      "nix"
      "lists"
      "enums"
      "data"
      "capabilities.nix"
    ];

    fallback = {
      names = [
        "writing"
        "conferencing"
        "development"
        "creation"
        "analysis"
        "management"
        "gaming"
        "multimedia"
        "administration"
        "automation"
      ];
      detail = {
        writing = {};
        conferencing = {};
        analysis = {};
        creation = {};
        management = {};
        gaming = {};
        multimedia = {};
        administration = {};
        automation = {};
        development = {
          languages = {};
          tools = {};
          platforms = {};
          environment = {};
        };
      };
    };

    vocabulary =
      if pathExists canonical
      then import canonical
      else fallback;
    inherit (vocabulary) names;
    values = vocabulary.detail;
  in {inherit names values;};

  default = registry.values;

  #? Capabilities are declared either as a list of names or as an attrset of
  #? names to detail. A name-only list resolves against `detail` and gets the
  #? full default shape, so a consumer that reads
  #? `capabilities.development.languages` never sees null just because the
  #? host wrote `["development"]`.
  #?
  #? A declared attrset keeps whatever detail it supplies, merged over the
  #? default for that name. That is what makes
  #? `development.languages.rust.channel` survive resolution.
  namesOf = value:
    if value == null
    then []
    else if isList value
    then unique value
    else if isAttrs value
    then unique (attrNames value)
    else throw "resolve user capabilities: expected a list of names or an attrset, but got ${typeOf value}";

  resolve = args: let
    declared = args.capabilities or default;
    resolvedNames = namesOf declared;
    unknown = filter (name: !(registry.values ? ${name})) resolvedNames;
    context = "resolve user capabilities";
    declaredIsAttrs = isAttrs declared;
    #? The default detail for one name, wrapped so it can be merged in.
    detailFor = name: {
      ${name} = registry.values.${name} or {};
    };
    #? A name-only list contributes the default detail for each name; an
    #? attrset is already detail and is used as written.
    detailFrom = value:
      if isList value
      then foldl' (acc: name: recursiveUpdate acc (detailFor name)) {} value
      else value;
    merged = recursiveUpdate registry.values (detailFrom declared);
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = ''
        unknown capabilities: ${toString unknown}
        known: ${toString registry.names}
      '';
    }; {
      #? The name list, and the detail attrset. Both are always available, so
      #? a consumer picks the shape it wants rather than inferring it from
      #? what the host happened to write.
      names = resolvedNames;
      detail = merged;
      isList = !declaredIsAttrs;
      values =
        if declaredIsAttrs
        then merged
        else resolvedNames;
      known = registry.names;
    };
in {inherit default namesOf registry resolve isList isAttrs;}
