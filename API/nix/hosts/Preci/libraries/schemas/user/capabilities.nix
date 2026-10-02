{
  lib,
  lix,
  sources ? null,
  ...
}: let
  inherit (lib.attrsets) attrNames isAttrs recursiveUpdate;
  inherit (lib.lists) elem filter isList unique;
  inherit (lix.debug) requireThat;

  #? The vocabulary lives in a pure data leaf under `Libraries`, for the same
  #? reason as `host/functionalities.nix`: the legacy enum is a `{_, ...}`
  #? module and cannot be read from outside its own tree.
  vocabulary =
    if sources == null
    then null
    else import (sources + "/Libraries/nix/lists/enums/data/capabilities.nix");

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

  canonical = if vocabulary == null then fallback else vocabulary;
  inherit (canonical) names detail;

  default = detail;

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
    else
      throw "resolve user capabilities: expected a list of names or an attrset, but got ${builtins.typeOf value}";

  resolve = {args ? {}}: let
    declared = args.capabilities or default;
    resolvedNames = namesOf declared;
    unknown = filter (name: !(elem name names)) resolvedNames;
    context = "resolve user capabilities";
    declaredIsAttrs = isAttrs declared;
    #? The default detail for one name, wrapped so it can be merged in.
    detailFor = name: {
      ${name} = detail.${name} or {};
    };
    #? A name-only list contributes the default detail for each name; an
    #? attrset is already detail and is used as written.
    detailFrom = value:
      if isList value
      then builtins.foldl' (acc: name: recursiveUpdate acc (detailFor name)) {} value
      else value;
    merged = recursiveUpdate detail (detailFrom declared);
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = ''
        unknown capabilities: ${toString unknown}
        known: ${toString names}
      '';
    };
    {
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
      known = names;
    };
in {
  inherit default resolve namesOf names detail;
  isList = isList;
  isAttrs = isAttrs;
}
