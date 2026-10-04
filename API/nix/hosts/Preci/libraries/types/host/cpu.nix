{lix, ...}: let
  inherit (lix.attrsets) isAttrs recursiveUpdate;
  inherit (lix.lists) elem elemAt foldl' length isList optional;
  inherit (lix.trivial) typeOf;
  inherit (lix.strings) fromJSON isString match showList splitString;

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
    parts = splitString "_" raw;
    at = item:
      if item < length parts
      then elemAt parts item
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

  resolve = value: let
    cpu =
      if value == null
      then default
      else if isAttrs value
      then recursiveUpdate default value
      else if isString value
      then fromString value
      else if isList value
      then foldl' (acc: item: recursiveUpdate acc (resolve item).cpu) default value
      else throw "cpu: cannot resolve ${typeOf value}";
    warnings = validate cpu;
  in {inherit cpu warnings;};
in {inherit default resolve arches brands;}
