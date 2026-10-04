/**
Kernel resolution for hosts.

Turns whatever a host declared as its kernel into a canonical record, and
chooses a cachyOS microarchitecture build when the host's CPU record is
specific enough to do so safely.
*/
{lix, ...}: let
  inherit (lix.lists) elem filter findFirstIndex head length optional take;
  inherit (lix.strings) concatStringsSep hasInfix isString showList toLower;
  inherit (lix.trivial) typeOf;

  /**
      Normalize whatever a host wrote for `cpu` -- a string, an attrset, a
      list, or null -- into the canonical record `confirms` reads.

      `kernel.nix` never sees the raw field.

      # Type

  ```
      getCpu :: AttrSet -> AttrSet
  ```
  */
  getCpu = lix.schemas.host.cpu.resolve;

  /**
      The resolved record a host with no declared kernel and an unplaceable CPU
      gets.

      `linuxPackages_latest` boots on anything and needs no loader, which is why
      it, rather than a cachyOS name, is the floor.

      # Type

  ```
      default :: { name :: String, vendor :: String, level :: Null }
  ```
  */
  default = {
    name = "linuxPackages_latest";
    vendor = "nixpkgs";
    level = null;
  };

  /**
      Microarchitecture levels, best first.

      "Best" is the highest level a CPU can execute: each step assumes the one
      below it, so this is a descending ladder rather than a set of independent
      options.

      A fact about CPUs, not about any host, so it lives in the schema.
      `context/` is where a host's declared kernel is compared against it.

      # Type

  ```
      levels :: [ { name :: String, brand :: String | Null, families :: [Int]?, models :: [Int]?, flags :: [String]? } ]
  ```
  */
  levels = [
    {
      name = "zen4";
      brand = "amd";
      # Zen 4 proper (family 19) and the Zen 4 refresh (family 25, models
      # 0x08/0x18/0x20/0x21/0x50/0x51/0x60/0x74/0x7f). Family 25 model 68 --
      # this host -- is Zen 3 and is deliberately absent, which is why its
      # ceiling is `x86_64-v3`.
      #
      # FIXME(review): several of these models are Zen 3, and 19 is not an
      # AMD family. See the review notes.
      families = [19 25];
      models = [8 24 32 33 80 81 96 116 127];
    }

    {
      name = "x86_64-v4";
      brand = null;
      # AVX-512 on top of the v3 feature set.
      flags = ["avx512f" "avx512bw" "avx512dq" "avx512vl"];
    }

    {
      name = "x86_64-v3";
      brand = null;
      # AVX2, BMI2, FMA, MOVBE, SSE4.2, CX16, LAHF/SAHF.
      flags = ["avx2" "bmi2" "fma" "movbe" "sse4_2" "cx16" "lahf_lm"];
    }

    {
      name = "x86_64-v2";
      brand = null;
      flags = ["sse4_2" "popcnt" "cx16"];
    }
  ];

  /**
      The variants a kernel name offers, best first, whether they are
      microarchitecture levels or vendor tuning.

      cachyOS publishes a kernel for each level; nixpkgs publishes the levels
      themselves. A vendor may also offer a *tuned* variant above a level --
      `zen4` requires no instruction beyond v3 but is unsafe on anything older --
      so the two are one ladder rather than separate concepts.

      Vendor entries are listed after the levels they can extend, so a name
      matching either resolves against the same ordering.

      # Type

  ```
      variants :: [ { name :: String | Null, brand :: String | Null, ... } ]
  ```
  */
  variants =
    levels
    ++ [
      {
        name = null;
        brand = null;
        # The foot of the ladder: a kernel with no variant suffix is the
        # unoptimised build, which every CPU can run. `name = null` means it is
        # matched by absence, never by name.
        flags = [];
      }
    ];

  /**
      The level a kernel name declares, or `null` when it declares none.

      A name may only match one entry: the ladder is descending and a kernel is
      built for exactly one level, so matching several would mean the name is
      ambiguous -- a spec error rather than a preference.

      # Inputs

      `kernel`

      : A kernel name, such as `linux-cachyos-zen4`.

      # Type

  ```
      levelOf :: String -> String | Null
  ```

      # Examples

      :::{.example}
      ## `levelOf` usage example

  ```nix
      levelOf "linux-cachyos-zen4"
      => "zen4"

      levelOf "linuxPackages_latest"
      => null
  ```
      :::
  */
  levelOf = kernel: let
    matched =
      filter (
        entry:
          if entry.name == null
          then false
          else hasInfix "-${entry.name}" kernel
      )
      variants;
  in
    if matched == []
    then null
    else (head matched).name;

  /**
      Whether a kernel name carries no variant suffix at all.

      # Inputs

      `kernel`

      : A kernel name.

      # Type

  ```
      unoptimised :: String -> Bool
  ```
  */
  unoptimised = kernel: levelOf kernel == null;

  /**
      Everything above `level` on the ladder, best first. Empty when `level` is
      already the best available, which is the case that needs no warning.

      `findFirstIndex` takes `(pred, default, list)` in this lib and `break` is
      absent, so the cut is found by asking for the index of the level and
      counting down to it. The default is `length names` -- one past the end --
      so a `null` level, which matches no entry, yields the whole ladder.

      FIXME(review): a `null` level *does* match the foot entry (`name = null`),
      so it yields every entry above the foot, not the foot as well. The result
      is what you want; the reason given above is not what happens.

      # Inputs

      `level`

      : A ladder entry name, or `null` for the unoptimised build.

      # Type

  ```
      isBetterThan :: String | Null -> [String]
  ```

      # Examples

      :::{.example}
      ## `isBetterThan` usage example

  ```nix
      isBetterThan "x86_64-v3"
      => ["zen4" "x86_64-v4"]

      isBetterThan "zen4"
      => []
  ```
      :::
  */
  isBetterThan = level: let
    names = map (entry: entry.name) variants;
    index = findFirstIndex (name: name == level) (length names) names;
  in
    map (entry: entry.name) (take index variants);

  /**
      The single best alternative for a kernel, or `null` when the declared
      kernel is already the best this ladder offers.

      # Inputs

      `kernel`

      : A kernel name.

      # Type

  ```
      better :: String -> String | Null
  ```

      # Examples

      :::{.example}
      ## `better` usage example

  ```nix
      better "linux-cachyos-x86_64-v3"
      => "zen4"

      better "linux-cachyos-zen4"
      => null
  ```
      :::
  */
  better = kernel: let
    betterThan = isBetterThan (levelOf kernel);
  in
    if betterThan != []
    then head betterThan
    else null;

  /**
      Whether a CPU record qualifies for a ladder entry.

      `specs.cpu` declares `arch` and `brand` only -- no family, model or
      feature flags -- so most entries cannot be *confirmed* from a spec, and
      an entry that cannot be confirmed must be excluded rather than assumed.
      That is the safe direction: the unsuffixed kernel boots everywhere,
      whereas `zen4` on a Zen 3 machine traps at the initramfs with an
      illegal-instruction fault and no shell.

      So an entry qualifies only when the record says enough:

      - `arch` must be `x86_64`, since the whole ladder is x86-64.
      - An entry carrying `brand` needs that brand in the record. Brand alone
        cannot *confirm* a level -- every AMD CPU in the last decade shares it --
        but it can rule one out: `zen4` on an Intel host is nonsense even if the
        family/model happen to line up.
      - An entry carrying `families`/`models` needs those in the record.
      - An entry carrying `flags` needs those in the record, which no spec has,
        so AVX-512 levels are never selected automatically.

      # Inputs

      `cpu`

      : The canonical CPU record: `arch`, and optionally `brand`, `family`,
        `model`.

      `entry`

      : A ladder entry from `variants`.

      # Type

  ```
      confirms :: AttrSet -> AttrSet -> Bool
  ```

      # Examples

      :::{.example}
      ## `confirms` usage example

  ```nix
      confirms {brand = "amd"; family = 25; model = 96;} (head levels)
      => true

      # Family 25 model 68 is Zen 3.
      confirms {brand = "amd"; family = 25; model = 68;} (head levels)
      => false
  ```
      :::
  */
  confirms = cpu: entry: let
    declared = {
      family = cpu.family or null;
      model = cpu.model or null;
      brand = cpu.brand or null;
    };
    requires = {
      family = entry ? families;
      brand = (entry.brand or null) != null;
      flags = (entry.flags or []) != [];
    };
  in
    !requires.flags
    && (!requires.brand || declared.brand == entry.brand)
    && (!requires.family || (declared.family != null && declared.model != null))
    && (
      if !requires.family
      then true
      else
        elem declared.family entry.families
        && elem declared.model entry.models
    );

  /**
      The best ladder entry a CPU record confirms, or `null` when nothing
      qualifies.

      Returned as the entry rather than its name so callers that need the full
      record (level, brand, flags) do not re-derive it.

      Deliberately conservative: `null` is the common answer until a host records
      family, model or feature flags. That is the correct answer, not a gap to
      paper over by guessing.

      FIXME(review): the foot entry (`name = null`) confirms for any `x86_64`
      record, so this returns that entry rather than `null` in the common case.
      `bestFor` hides the difference.

      # Inputs

      `cpu`

      : The canonical CPU record.

      # Type

  ```
      bestEntryFor :: AttrSet -> AttrSet | Null
  ```
  */
  bestEntryFor = cpu: let
    eligible =
      filter
      (entry: (cpu.arch or null) == "x86_64" && confirms cpu entry)
      variants;
  in
    if eligible == []
    then null
    else head eligible;

  /**
      The name of the best level a CPU confirms, or `null`.

      # Inputs

      `cpu`

      : The canonical CPU record.

      # Type

  ```
      bestFor :: AttrSet -> String | Null
  ```
  */
  bestFor = cpu: let
    entry = bestEntryFor cpu;
  in
    if entry == null
    then null
    else entry.name;

  /**
      The vendor prefixes a kernel name may carry, and what each means.

      Dispatch is on content, not on a separate `vendor` field on the host -- a
      second field would be a second place to keep in step with the name, and the
      name is already the only statement of what a host wants.

      | Form                 | Meaning                                                                                            |
      | -------------------- | -------------------------------------------------------------------------------------------------- |
      | `linuxPackages_*`    | A nixpkgs kernel. Used as-is; the ladder does not apply, because nixpkgs names its own variants.   |
      | `linux-cachyos-*`    | A cachyOS kernel. The suffix, if any, is a level.                                                  |
      | `cachyos` / `cachy`  | Shorthand for "whatever cachyOS publishes for this CPU". Completed to `linux-cachyos-<best>`.      |

      # Type

  ```
      prefixes :: { cachyos :: String, nixpkgs :: String }
  ```
  */
  prefixes = {
    cachyos = "linux-cachyos";
    nixpkgs = "linuxPackages";
  };

  /**
      Parse a kernel string into the canonical record.

      A bare vendor request keeps its own name and `level = null`; `resolve`
      completes it. An explicit variant is kept as-is -- a spec is a decision,
      not something to second-guess.

      # Inputs

      `value`

      : A kernel string. Accepted forms are listed in the examples.

      # Type

  ```
      fromString :: String -> { name :: String, vendor :: String, level :: String | Null }
  ```

      # Examples

      :::{.example}
      ## `fromString` usage example

  ```nix
      fromString "linuxPackages_latest"
      => { name = "linuxPackages_latest"; vendor = "nixpkgs"; level = null; }

      fromString "linux-cachyos-zen4"
      => { name = "linux-cachyos-zen4"; vendor = "cachyos"; level = "zen4"; }

      fromString "cachyos"
      => { name = "cachyos"; vendor = "cachyos"; level = null; }
  ```
      :::
  */
  fromString = value: let
    isCachy = hasInfix "cachy" (toLower value);
  in
    if isCachy
    then {
      name = value;
      vendor = "cachyos";
      level = levelOf value;
    }
    else {
      name = value;
      vendor = "nixpkgs";
      level = null;
    };

  /**
      Resolve whatever a host declared into `{name, vendor, level, warnings}`.

      The record has no `package`: turning a name into a derivation needs a
      package set, and this file has none. `context/packages.nix` looks the name
      up after resolution.

      A host may declare its kernel at `host.kernel` (current) or
      `host.packages.kernel` (legacy). Both mean the same thing; the first wins
      when both are set, so a host migrating can write the new field and delete
      the old one without a window where neither is read.

      Policy, in order:

      1. Host declared a kernel -- use it. A bare cachyOS request is completed
         with the CPU's best level.
      2. Host declared nothing, CPU can be placed on the ladder --
         `linux-cachyos-<best>`.
      3. Host declared nothing, CPU cannot be placed -- `default`
         (`linuxPackages_latest`).

      # Inputs

      `host`

      : The host attrset. Reads `kernel`, `packages.kernel` and, through
        `getCpu`, `cpu`.

      # Type

  ```
      resolve :: { host :: AttrSet } -> { name :: String, vendor :: String, level :: String | Null, warnings :: [String] }
  ```

      # Examples

      :::{.example}
      ## `resolve` usage example

  ```nix
      resolve {host = {kernel = "linuxPackages_latest";};}
      => { name = "linuxPackages_latest"; vendor = "nixpkgs"; level = null; warnings = []; }
  ```
      :::
  */
  resolve = {host}: let
    cpu = getCpu host;
    value = host.kernel or host.packages.kernel or null;

    parsed =
      if value == null
      then null
      else if isString value
      then fromString value
      else throw "kernel: cannot resolve ${typeOf value}";

    # A bare cachyOS request has no level of its own, so the CPU supplies
    # one. A name that already carries a level is left alone.
    bare =
      parsed
      != null
      && parsed.vendor == "cachyos"
      && parsed.level == null;

    # Computed once. Used by the cachyOS branch and by both warnings, so the
    # filter over `variants` runs a single time per resolution.
    best =
      if bare || parsed == null
      then bestFor cpu
      else null;
  in
    (
      if parsed != null && !bare
      then parsed
      else if best != null
      then let
        level = best;
        name = concatStringsSep "-" [prefixes.cachyos level];
        vendor = "cachyos";
      in {inherit level name vendor;}
      else default
    )
    // {
      warnings =
        optional (bare && best == null) ''
          kernel: host declares '${toString value}' but the CPU records no
          microarchitecture level; using '${default.name}' instead of a cachyOS
          build.
        ''
        ++ optional (parsed == null && best == null) ''
          kernel: no kernel declared and the CPU records no microarchitecture
          level; using '${default.name}'.
        '';
    };

  /**
      Render a warning naming what was declared and what would serve it better.

      Kept here so the vocabulary and the prose cannot drift apart.

      # Inputs

      `name`

      : The declared kernel name.

      `level`

      : (optional) The level `name` targets. Defaults to `levelOf name`.

      `alternatives`

      : (optional) Better entries. Defaults to `isBetterThan level`.

      # Type

  ```
      describe :: { name :: String, level :: String | Null ?, alternatives :: [String] ? } -> String
  ```
  */
  describe = {
    name,
    level ? levelOf name,
    alternatives ? isBetterThan level,
  }: "kernel '${name}' targets level '${
    toString level
  }'; better for this host: ${showList alternatives}";
in {
  inherit
    default
    levels
    variants
    levelOf
    unoptimised
    isBetterThan
    better
    confirms
    bestEntryFor
    bestFor
    prefixes
    fromString
    resolve
    describe
    ;
}
