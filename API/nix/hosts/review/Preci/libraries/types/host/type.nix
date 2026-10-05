{lix, ...}: let
  inherit (lix.attrsets) isAttrs;
  inherit (lix.lists) elem filter foldl' head optional;
  inherit (lix.strings) showList splitString toLower;

  #? Machine types, each group led by its canonical name and followed by its
  #? synonyms.
  #?
  #? A list of lists rather than an attrset because the canonical name is the
  #? first element, not a key -- so it appears once per group, and the groups
  #? keep declaration order. Keyed access is not needed: lookup scans, and the
  #? canonical set is `map head`.
  #?
  #? The set is closed: an unrecognised value is kept and a warning is
  #? emitted, rather than guessed at. Downstream branches on the type -- a
  #? module that does one thing for `laptop` and another for `desktop` should
  #? not silently do neither because someone wrote `notebook` and it was not
  #? folded in here.
  types = [
    ["laptop" "notebook" "portable" "ultrabook"]
    ["desktop" "workstation" "tower"]
    ["server" "headless" "rack"]
    ["vm" "virtual" "virtualmachine"]
    ["container" "docker" "lxc"]
  ];

  #? Canonical names in declaration order.
  canonical = map head types;

  default = "desktop";

  #? First non-null value among a list of attribute paths, e.g.
  #? `["type" "machine" "specs.type"]`. Each path is resolved against `host`;
  #? a missing step yields null rather than throwing.
  firstOf = host: paths: let
    pick = path: let
      parts = splitString "." path;
    in
      foldl'
      (value: part:
        if isAttrs value
        then value.${part} or null
        else null)
      host
      parts;
    found = filter (value: value != null) (map pick paths);
  in
    if found == []
    then null
    else head found;

  #? The canonical name for a lowercased input, or the input itself when no
  #? group contains it.
  canonicalOf = lowered: let
    matches = filter (group: elem lowered group) types;
  in
    if matches == []
    then lowered
    else head (head matches);

  #? Normalize a type string that is already in hand.
  normalize = value: let
    type = canonicalOf (toLower value);
  in {
    inherit type;
    warnings = optional (!elem type canonical) ''
      type: unrecognised machine type '${value}'; known: ${showList canonical}
    '';
  };

  #? Normalize whatever a host declared -- via `host.type`, `host.machine`,
  #? or either under `host.specs.*` -- into one of `canonical`.
  #?
  #? Accepts:
  #?
  #?   null / absent    -> default
  #?   "laptop"         -> "laptop"
  #?   "notebook"       -> "laptop" (synonym)
  #?   "LAPTOP"         -> "laptop" (case-folded)
  #?
  #? The four field locations are tried in order, first present wins. `type`
  #? is the current name; `machine` and `specs.*` are accepted so a host
  #? migrating does not need a window where neither is read.
  resolve = args: let
    raw = firstOf args [
      "type"
      "machine"
      "specs.type"
      "specs.machine"
    ];
  in
    if raw == null
    then {
      type = default;
      warnings = [];
    }
    else normalize raw;

  #? Standalone check for a value that is already canonical. Exported so a
  #? consumer that receives a type by other means can assert it without
  #? normalizing again.
  validate = type:
    optional (!elem type canonical)
    "type: unrecognised machine type '${type}'; known: ${showList canonical}";
in {inherit types canonical default normalize resolve validate;}
