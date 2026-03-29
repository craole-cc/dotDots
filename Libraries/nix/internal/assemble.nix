{
  lib',
  customLib,
  path,
}:
lib'.attrsets.removeAttrs customLib [
  "__unfix__"
  "unfix"
  "extend"
]
// {
  inherit path;
  extend = f: customLib.extend f;
  src = path;
  lib = lib';

  options =
    lib'.options or {}
    // lib'.modules or {}
    // customLib.types.options or {};

  types =
    customLib.types or {}
    // lib'.types or {}
    // lib'.options or {}
    // customLib.types.options or {}
    // customLib.types.predicates or {};
}
