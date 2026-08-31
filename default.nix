{
  src ? ./.,
  stems ? {},
  paths ? {},
  flake ? {},
  names ? {},
  lib ? null,
  ...
} @ args: let
  bootstrap = rec {
    inherit (builtins) attrNames concatStringsSep elem filter foldl' head isAttrs isFunction isList isPath isString listToAttrs pathExists readDir replaceStrings split stringLength substring tail toJSON typeOf;

    getEnvOr = key: fallback: let
      value = builtins.getEnv key;
    in
      if value == ""
      then fallback
      else value;

    asAttrs = arg: let
      isKwargs =
        isAttrs arg
        && (arg ? condition || arg ? name || arg ? value);
      condition =
        if isKwargs
        then arg.condition or true
        else true;
      name =
        if isKwargs
        then arg.name or null
        else null;
      value =
        if isKwargs
        then arg.value or arg
        else arg;
    in
      if
        condition
        && (isAttrs value && value != {})
      then
        if name != null
        then {"${name}" = value;}
        else value
      else {};

    toUpper = value:
      replaceStrings
      ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"]
      ["A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]
      value;

    toLower = value:
      replaceStrings
      ["A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]
      ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"]
      value;

    toPascalCase = str: let
      #> Dictionary for strict acronym preservation
      acronyms = {
        "api" = "API";
        "ssh" = "SSH";
        "tui" = "TUI";
        "cli" = "CLI";
      };
      firstChar = substring 0 1 str;
      restChars = substring 1 (stringLength str - 1) str;
    in
      if acronyms ? ${str}
      then acronyms.${str}
      else (toUpper firstChar) + restChars;

    toCamelCase = str: let
      #> Maps specific structural exceptions back to uniform lowercase
      acronyms = {
        "API" = "api";
        "SSH" = "ssh";
        "TUI" = "tui";
        "CLI" = "cli";
        "api" = "api";
      };
      firstChar = substring 0 1 str;
      restChars = substring 1 (stringLength str - 1) str;
    in
      if acronyms ? ${str}
      then acronyms.${str}
      else (toLower firstChar) + restChars;

    isFlakeLike = value:
      isAttrs value
      && value ? inputs
      && isAttrs value.inputs
      && (
        (value ? _type && value._type == "flake")
        || value ? sourceInfo
        || value ? outputs
      );

    isNixpkgsLike = value:
      isAttrs value
      && value ? lib
      && (value ? legacyPackages || value ? packages);

    findFirst = pred: default: list:
      foldl'
      (
        acc: x:
          if acc != default
          then acc #? already found
          else if pred x
          then x #? this one matches
          else default
      )
      default
      list;

    normalizeFlake = set: let
      core =
        if isFlakeLike set
        then
          findFirst
          (name: isNixpkgsLike (set.inputs.${name} or null))
          null
          [
            "nixpkgs"
            "nixPackages"
            "nixPackagesUnstable"
            "nixPackagesStable"
            "nixpkgs-unstable"
            "nixpkgs-stable"
            "unstable"
            "stable"
            "nixos"
            "pkgs"
          ]
        else null;
    in
      set
      // {
        inputs =
          if core != null && core != "nixpkgs"
          then set.inputs // {nixpkgs = set.inputs.${core};}
          else set.inputs or {};
      };

    normalizeLib = {
      lib ? null,
      flake ? {},
      bootstrap ? {},
      overrides ? {},
      ...
    }: let
      flake' = normalizeFlake flake;
    in
      mergeAttrsRecursive
      (mergeAttrsRecursive bootstrap (
        if lib != null && isAttrs lib && lib ? trivial
        then lib
        else if flake' ? inputs.nixpkgs.lib
        then flake'.inputs.nixpkgs.lib
        else import <nixpkgs/lib>
      ))
      (
        if overrides != null
        then overrides
        else {}
      );

    normalizePath = {
      part,
      vars,
    }: let
      isVar = value: isAttrs value && value ? var && isString value.var;
    in
      if isList part
      then
        concatStringsSep "/" (
          map
          (part: normalizePath {inherit part vars;})
          part
        )
      else if isString part || isPath part
      then toString part
      else if isVar part
      then
        if elem part.var vars
        then getEnvOr part.var "\${${part.var}}"
        else throw "resolvePath: unknown variable \"${part.var}\". Allowed: ${toJSON vars}"
      else throw "resolvePath: unsupported path segment: ${toJSON part}";

    unique = list: let
      acc = list: seen:
        if list == []
        then seen
        else let
          x = head list;
          xs = tail list;
        in
          if elem x seen
          then acc xs seen
          else acc xs (seen ++ [x]);
    in
      acc list [];

    mergeAttrsRecursive = let
    in
      set1: set2:
        if isAttrs set1 && isAttrs set2
        then let
          keys = unique (attrNames set1 ++ attrNames set2);
        in
          listToAttrs (
            map (key: {
              name = key;
              value =
                if set1 ? ${key} && set2 ? ${key}
                then mergeAttrsRecursive set1.${key} set2.${key}
                else set2.${key} or set1.${key};
            })
            keys
          )
        else set2;

    resolvePath = {
      name ? null, #? Optional: Connects to your stems.${name} and paths.${name} overrides
      stem ? [], #? Fallback folder path array or string
      root ? "core", #? Specific: Selects a semantic base mapping from roots
      vars ? [],
      envPrefix ? null,
      known ? paths,
      roots ?
        paths.roots or {
          core = "";
          home = {var = "HOME";};
          root = "/";
          xdg = {var = "HOME";};
        },
    }: let
      derived = {
        stem =
          if name != null
          then stems.${name} or null
          else null;
        path =
          if name != null
          then known.${name} or null
          else null;
      };

      defined = {
        stem = let
          spec = derived.stem;
          parsed =
            if isList spec
            then
              filter
              (part: isString part && part != "")
              spec
            else if isString spec
            then
              filter
              (part: isString part && part != "")
              (split "/" (replaceStrings ["."] ["/"] spec))
            else [];
        in
          if parsed != []
          then parsed
          else
            (
              if isList stem
              then stem
              else [stem]
            );

        path = let
          spec = derived.path;
        in
          if isPath spec
          then spec
          else if spec != null && (!isString spec || spec == "")
          then throw "paths.${name} must be a path or non-empty string, got ${typeOf spec}"
          else if spec != null && isString spec
          then spec
          else defined.stem;
      };

      resolved = let
        normalize = part: normalizePath {inherit part vars;};

        root' = {
          active = roots.${root} or (throw "resolvePath: unknown root alias \"${root}\"");
          base = normalize root'.active;
        };

        stem' = {
          target = normalize defined.path;
          absolute = (stem'.target != "") && substring 0 1 stem'.target == "/";
        };

        join = base:
          if stem'.absolute
          then stem'.target
          else if base == ""
          then stem'.target
          else if stem'.target == ""
          then base
          else if base == "/"
          then "/${stem'.target}"
          else "${base}/${stem'.target}";

        #> 1. Define your exact architectural root prefix characters map
        rootPrefixes = {
          core = defined.names.lib or (derived.names.lib or (names.lib or "lix"));
          root = "ROOT";
          xdg = "XDG";
          home = "";
        };

        #> 2. Determine the active base root character prefix string
        activeRootPrefix = rootPrefixes.${root} or "";

        #> 3. Isolate the target name segment (prefer 'name', then the first word of the stem)
        targetSegments =
          if name != null && name != ""
          then [name]
          else
            (
              if defined.stem != []
              then [(head defined.stem)]
              else []
            );
      in {
        stem = defined.stem;

        path = {
          local =
            if isPath defined.path
            then defined.path
            else
              (
                if stem'.absolute
                then /. + stem'.target
                else join root'.base
              );
          store = let
            base =
              if isPath defined.path
              then defined.path
              else
                (
                  if stem'.absolute
                  then /. + stem'.target
                  else join "."
                );
          in
            if isPath base
            then base
            else ./. + "/${base}";
        };

        #> 4. Dynamic environment builder honoring your character parameter hierarchy rules
        env = concatStringsSep "_" (
          (
            if activeRootPrefix != ""
            then [(toUpper (replaceStrings ["-"] ["_"] activeRootPrefix))]
            else []
          )
          ++ map
          (str: toUpper (replaceStrings ["-"] ["_"] str))
          (
            filter
            (str: str != "default" && isString str)
            targetSegments
          )
        );
      };
    in
      resolved;

    #> importModules returns { value; stems; }.
    #>
    #> - value: SAME shape/content as today's bare-attrset output. Nothing downstream
    #>   that consumes `modules.api.global` etc. needs to change.
    #> - stems: mirrors value's shape; every leaf is a flat path-segment list, e.g.
    #>   stems.api.global == [ "API" "global" ]  (or [ "API" "nix" "global" ] if your
    #>   real layout has an intermediate "nix" dir — see note at bottom).
    #>
    #> GROWS, NOT OVERRIDES:
    #> - No leaf default.nix needs to change. The existing
    #>     {importModules ? (import ../. {}).lib.importModules, ...}: importModules ./.
    #>   pattern keeps working verbatim.
    #> - Its `importModules ? <fallback>` default is simply never triggered once called
    #>   from inside a walk, because the parent now supplies a live `importModules` (and
    #>   the rest of the real `args`) directly in extraArgs. The fallback still matters
    #>   for anyone importing that one file standalone, outside any walk — unchanged.
    #> - Stems are computed ENTIRELY by the parent watching its own `readDir`; the child
    #>   never needs to know a stem/path concept exists, so old and new leaves behave
    #>   identically from the child's point of view.
    importModules = input: let
      isDirectPath = isPath input || isString input;
      path =
        if isDirectPath
        then input
        else input.path;
      stemSoFar =
        if isDirectPath
        then []
        else (input.stem or []);

      #! The one addition that fixes both the stems problem AND the pre-existing
      #! args-reset-at-every-leaf bug: children receive the SAME live importModules
      #! (so their `importModules ? fallback` default never fires) plus the real,
      #! un-reset args from the top of the tree — instead of each leaf silently
      #! re-bootstrapping the whole library from `{}` via `(import ../. {}).lib.importModules`.
      extraArgs =
        (
          if isDirectPath
          then args
          else args // (input.args or {})
        )
        // {inherit importModules;};

      callImport = target: let
        exec = import target;
      in
        if isFunction exec
        then exec extraArgs
        else exec;
    in
      if !pathExists (path + "/.")
      then {
        value = callImport path;
        stems = null; #? not a directory: leaf has no children to mirror
      }
      else let
        data = readDir path;

        isLoadable = name:
          name
          != "nix"
          && data.${name} == "directory"
          && pathExists (path + "/${name}/default.nix");

        #> `nix` is deliberately excluded from normal recursion below (isLoadable),
        #> so it must be walked here explicitly, and — critically — BOTH its .value
        #> AND its .stems need to flow onward. Discarding .stems here would make
        #> everything under e.g. API/nix/{global,hosts,options,users} invisible to
        #> the stems tree, even though isLoadable will still find `global` etc. as
        #> loadable children of the `nix` dir on its own recursive walk.
        nixWalk =
          if pathExists (path + "/nix/default.nix")
          then
            importModules {
              path = path + "/nix";
              stem = stemSoFar ++ ["nix"];
            }
          else {
            value = {};
            stems = {};
          };
        base = nixWalk.value;
        baseStems = nixWalk.stems;

        childNames = filter isLoadable (attrNames data);

        #> Each child is walked via THIS SAME importModules (real recursion now,
        #> not filesystem re-entry) so it too returns { value; stems; }.
        children =
          map (name: {
            inherit name; #! real on-disk casing, straight from readDir's attrNames
            result = importModules {
              path = path + "/${name}";
              stem = stemSoFar ++ [name];
            };
          })
          childNames;

        others = listToAttrs (map (child: let
            importedValue = child.result.value;
          in {
            #! Exact on-disk name, not toCamelCase'd — QBX and TheOracle must stay
            #! QBX and TheOracle. This is a deliberate break from the old camelCase
            #! keying (modules.value.api.hosts.qBX -> .QBX), needed because hostnames
            #! and similar real identifiers are genuinely case-sensitive.
            name = child.name;
            value =
              if importedValue == null
              then {}
              else importedValue; #! no re-keying: whatever the leaf returned is returned as-is
          })
          children);

        siblingStems = listToAttrs (map (child: {
            name = child.name; #! exact, matches `others` above
            value =
              #? child had its own loadable subdirs -> mirror value's nested shape
              #? child was a leaf (or had none) -> flat accumulated segment list
              if child.result.stems != null && child.result.stems != {}
              then child.result.stems
              else stemSoFar ++ [child.name];
          })
          children);

        #! baseStems first, siblingStems second: if a real subdirectory name ever
        #! collides with something surfaced from under `nix/`, the directly-loaded
        #! sibling wins — mirrors how `others`' shallow merge already treats direct
        #! children as authoritative over base-derived content.
        otherStems = baseStems // siblingStems;
      in {
        value = base // others;
        stems = otherStems;
      };

    #> NOTE on the "nix" segment: `isLoadable` excludes any subdir literally named
    #> "nix" from normal recursion (it's handled separately via `base`, one level
    #> up, immediately). If your real layout is API/nix/global (an intermediate
    #> "nix" folder), `base`'s stem above now correctly includes it. If instead
    #> global/hosts/rust/users sit DIRECTLY under API/ with no intermediate `nix`
    #> folder, `base` never fires there (no API/nix/default.nix) and this is moot
    #> for that branch. Confirm your actual layout before relying on stems output —
    #> this was the open question from before.

    importModulesOLD = input: let
      isDirectPath = isPath input || isString input;
      path =
        if isDirectPath
        then input
        else input.path;

      extraArgs =
        (
          if isDirectPath
          then args
          else args // (input.args or {})
        )
        // {inherit importModules;};

      callImport = target: let
        exec = import target;
      in
        if isFunction exec
        then exec extraArgs
        else exec;
    in
      if !pathExists (path + "/.")
      then callImport path
      else let
        data = readDir path;

        isLoadable = name:
          name
          != "nix"
          && data.${name} == "directory"
          && pathExists (path + "/${name}/default.nix");

        base =
          if pathExists (path + "/nix/default.nix")
          then callImport (path + "/nix")
          else {};

        others = listToAttrs (map (name: let
          importedValue = callImport (path + "/${name}");
        in {
          name = toCamelCase name;
          value =
            if importedValue == null
            then {}
            else if isAttrs importedValue
            then
              listToAttrs (map (key: {
                name = toCamelCase key;
                value = importedValue.${key};
              }) (attrNames importedValue))
            else importedValue;
        }) (filter isLoadable (attrNames data)));
      in
        base // others;

    sourceLib = extraArgs:
      import ./. (args // extraArgs);
  };

  derived = with bootstrap; {
    modules = importModules {
      inherit args;
      path = src;
    };

    flake = normalizeFlake flake;
    lib = normalizeLib {inherit lib bootstrap flake;};

    # paths = mergeAttrsRecursive paths {
    #   src = resolvePath {name = "src";};
    #   lib = resolvePath {
    #     name = "lib";
    #     stem = ["Libraries" "nix"];
    #   };
    # };

    names =
      mergeAttrsRecursive {
        src = "dots";
        lib = "lix";
        top = "_";
      }
      names;

    args = args // {inherit (derived) flake lib modules;};
  };
  # defined = {};
  # resolved = import derived.paths.lib.path.store derived.args;
in
  derived
