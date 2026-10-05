{lix, ...}: let
  inherit (lix.attrsets) filterAttrs isAttrs recursiveUpdate;
  inherit (lix.lists) elem elemAt filter findFirst foldl' isList length optional;
  inherit (lix.strings) hasPrefix removePrefix fromJSON isString match showList splitString concatStringsSep typeOf;

  default = {
    arch = "x86_64";
    brand = null;
    family = null;
    model = null;
    flags = [];
  };

  arches = ["x86_64" "aarch64"];
  brands = ["intel" "amd"];

  fromString = raw: let
    knownArch = findFirst (arch: hasPrefix arch raw) null arches;
    remainder =
      if knownArch == null
      then raw
      else removePrefix knownArch raw;
    parts = filter (part: part != "") (splitString "_" remainder);
    fields =
      if knownArch == null
      then parts
      else [knownArch] ++ parts;
    at = item:
      if item < length fields
      then elemAt fields item
      else null;
    toInt = input:
      if input == null
      then null
      else if match "[0-9]+" input != null
      then fromJSON input
      else input;
  in
    recursiveUpdate default {
      arch = at 0;
      brand = at 1;
      family = toInt (at 2);
      model = toInt (at 3);
    };

  parseRaw = item:
    if isAttrs item
    then item
    else if isString item
    then filterAttrs (attrName: attrValue: attrValue != null) (fromString item)
    else throw "cpu: cannot parse ${typeOf item}";

  parse = item: recursiveUpdate default (parseRaw item);

  validate = cpu: let
    has = name: cpu.${name} != null;
    flag = cond: msg: optional cond msg;
  in
    flag (!elem cpu.arch arches)
    "cpu: unknown arch '${toString cpu.arch}'; known: ${showList arches}"
    ++ flag (cpu.brand != null && !elem cpu.brand brands)
    "cpu: unknown brand '${toString cpu.brand}'; known: ${showList brands}"
    ++ flag (has "family" != has "model")
    "cpu: family and model must be set together; got family=${toString cpu.family} model=${toString cpu.model}"
    ++ flag (!isList cpu.flags)
    "cpu: flags must be a list; got ${typeOf cpu.flags}";

  resolve = args: let
    value =
      if isAttrs args
      then args.cpu or (args.specs.cpu or args)
      else args;

    cpu =
      if value == null
      then default
      else if isList value
      then
        recursiveUpdate default (
          foldl'
          (acc: item: recursiveUpdate acc (parseRaw item))
          {}
          value
        )
      else parse value;

    warnings = validate cpu;
  in
    (
      if warnings != []
      then
        throw ''
          cpu: invalid configuration
          ${concatStringsSep "\n" (map (warning: "  - ${warning}") warnings)}
        ''
      else cpu
    )
    // {inherit warnings;};
in {inherit default resolve validate arches brands;}
