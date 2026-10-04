{lix, ...}: let
  inherit (lix.lists) elem head filter length take;
  inherit (lix.lists) findFirstIndex;
  inherit (lix.strings) concatStringsSep hasInfix;

  #? Microarchitecture levels, best first. "Best" is the highest level a CPU
  #? can execute: each step assumes the one below it, so this is a descending
  #? ladder rather than a set of independent options.
  #?
  #? A fact about CPUs, not about any host, so it lives in the schema.
  #? `context/` is where a host's declared kernel is compared against it.
  levels = [
    {
      name = "zen4";
      brand = "amd";
      #? Zen 4 proper (family 19) and the Zen 4 refresh (family 25, models
      #? 0x08/0x18/0x20/0x21/0x50/0x51/0x60/0x74/0x7f). Family 25 model 68 --
      #? this host -- is Zen 3 and is deliberately absent, which is why its
      #? ceiling is `x86_64-v3`.
      families = [19 25];
      models = [8 24 32 33 80 81 96 116 127];
    }

    {
      name = "x86_64-v4";
      brand = null;
      #? AVX-512 on top of the v3 feature set.
      flags = ["avx512f" "avx512bw" "avx512dq" "avx512vl"];
    }

    {
      name = "x86_64-v3";
      brand = null;
      #? AVX2, BMI2, FMA, MOVBE, SSE4.2, CX16, LAHF/SAHF.
      flags = ["avx2" "bmi2" "fma" "movbe" "sse4_2" "cx16" "lahf_lm"];
    }

    {
      name = "x86_64-v2";
      brand = null;
      flags = ["sse4_2" "popcnt" "cx16"];
    }
  ];

  #? The variants a kernel name offers, best first, whether they are
  #? microarchitecture levels or vendor tuning. cachyOS publishes a kernel for
  #? each level; nixpkgs publishes the levels themselves. A vendor may also
  #? offer a *tuned* variant above a level -- `zen4` requires no instruction
  #? beyond v3 but is unsafe on anything older -- so the two are one ladder
  #? rather than separate concepts.
  #?
  #? Vendor entries are listed after the levels they can extend, so a name
  #? matching either resolves against the same ordering.
  variants =
    levels
    ++ [
      {
        name = null;
        brand = null;
        #? The foot of the ladder: a kernel with no variant suffix is the
        #? unoptimised build, which every CPU can run. `name = null` means it is
        #? matched by absence, never by name.
        flags = [];
      }
    ];

  #? The level a kernel name declares, or `null` when it declares none.
  #?
  #? A name may only match one entry: the ladder is descending and a kernel is
  #? built for exactly one level, so matching several would mean the name is
  #? ambiguous -- a spec error rather than a preference.
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

  #? Whether a kernel name carries no variant suffix at all.
  unoptimised = kernel: levelOf kernel == null;

  #? Everything above `level` on the ladder, best first. Empty when `level` is
  #? already the best available, which is the case that needs no warning.
  #?
  #? `findFirstIndex` takes `(pred, default, list)` in this lib and `break` is
  #? absent, so the cut is found by asking for the index of the level and
  #? counting down to it. A `null` level -- an unsuffixed kernel -- matches
  #? nothing, so the whole ladder is returned and the `null` entry at the foot
  #? is the only thing that is not a name.
  isBetterThan = level: let
    names = map (entry: entry.name) variants;
    missing = map (entry: entry.name) [null];
    index = findFirstIndex (name: name == level) missing names;
    count =
      if index == missing
      then length names
      else index;
  in
    map (entry: entry.name) (take count variants);

  #? The single best alternative for a kernel, or `null` when the declared
  #? kernel is already the best this ladder offers.
  better = kernel: let
    better = isBetterThan (levelOf kernel);
  in
    if better != []
    then head better
    else null;

  #? Whether a CPU record qualifies for a ladder entry.
  #?
  #? `specs.cpu` declares `arch` and `brand` only -- no family, model or
  #? feature flags -- so most entries cannot be *confirmed* from a spec, and
  #? an entry that cannot be confirmed must be excluded rather than assumed.
  #? That is the safe direction: the unsuffixed kernel boots everywhere,
  #? whereas `zen4` on a Zen 3 machine traps at the initramfs with an
  #? illegal-instruction fault and no shell.
  #?
  #? So an entry qualifies only when the record says enough:
  #?
  #?   - `arch` must be `x86_64`, since the whole ladder is x86-64.
  #?   - An entry carrying `families`/`models` needs those in the record. A
  #?     `brand = "amd"` alone is not enough: every AMD CPU in the last
  #?     decade shares that brand, including the ones `zen4` is unsafe on.
  #?   - An entry carrying `flags` needs those in the record, which no spec
  #?     has, so AVX-512 levels are never selected automatically.
  #?
  #? What is left is confirmable on the spec's own terms: an entry with no
  #? CPU requirement at all, which is the unsuffixed build.
  confirms = cpu: entry:
    let
      declaredFamily = cpu.family or null;
      declaredModel = cpu.model or null;
      needsFamily = entry ? families;
      needsFlags = (entry.flags or []) != [];
    in
      !needsFlags
      && (!needsFamily || (declaredFamily != null && declaredModel != null))
      && (
        if !needsFamily
        then true
        else
          elem declaredFamily entry.families && elem declaredModel entry.models
      );

  #? The highest level a CPU record confirms, best-first, or `null` when
  #? nothing qualifies -- in which case the caller keeps the unsuffixed build.
  #?
  #? Deliberately conservative: `null` is the common answer until `specs.cpu`
  #? records a family, model or feature flags. That is the correct answer, not
  #? a gap to paper over by guessing.
  bestFor = cpu:
    let
      eligible =
        filter (entry: (cpu.arch or null) == "x86_64" && confirms cpu entry) variants;
    in
      if eligible == []
      then null
      else (head eligible).name;
in {
  inherit levels variants levelOf unoptimised isBetterThan better confirms bestFor;
  #? Render a warning naming what was declared and what would serve it better.
  #? Kept here so the vocabulary and the prose cannot drift apart.
  describe = {
    kernel,
    level ? levelOf kernel,
    alternatives ? isBetterThan level,
  }: "kernel '${kernel}' targets level '${
    toString level
  }'; better for this host: ${
    concatStringsSep ", " alternatives
  }";
}
