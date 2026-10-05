{lix, ...}: let
  inherit (lix.attrsets) attrNames;
  inherit (lix.strings) concatStringsSep replaceStrings stringLength substring toLower toUpper;
  inherit (lix.lists) filter foldl' head tail toList unique;
  inherit (lix.trivial) isNotEmpty;

  showList = names:
    concatStringsSep ", " (
      map (name: "'${name}'") names
    );

  #> Render a dotted path list as a string, e.g. ["paths" "roots" "src"] -> "paths.roots.src"
  showPath = path: concatStringsSep "." path;

  /**
  Upper-case the first character of a string, leaving the rest unchanged.

  # Inputs

  `text`
  : String to capitalize. Must be non-empty (an empty string will error,
    since `substring 0 1 ""` is `""` and `toUpper ""` is fine, but callers
    relying on a non-empty result should check first).

  # Type

  ```
  capitalize :: String -> String
  ```

  # Example

  ```nix
  capitalize "nixos"  # => "Nixos"
  capitalize "Nix"    # => "Nix"
  ```
  */
  capitalize = text:
    toUpper (substring 0 1 text) + substring 1 (-1) text;

  mkPath = root: stems:
    concatStringsSep "/" (
      map toString (
        filter isNotEmpty (
          (toList root) ++ (toList stems)
        )
      )
    );
  mkPathLiteral = root: stems: let
    parts = filter isNotEmpty ((toList root) ++ (toList stems));
  in
    if parts == []
    then ""
    else
      foldl'
      (acc: part: acc + "/${toString part}")
      (head parts)
      (tail parts);

  #? Reduce a name to comparable form: lowercase, with every run of
  #? separators collapsed to a single `-` and the ends trimmed. So
  #? `Zen_Twilight`, `zen.twilight` and `zen-twilight` all reduce to
  #? `zen-twilight`, and a stray trailing separator is not a different name.
  #?
  #? This is the *shape* of a name, not its meaning. Turning `zen-twilight`
  #? into the key `twilight` is a different question, answered by an alias table
  #? -- see `lix.strings.aliases`. Keeping the two apart is deliberate: shape
  #? reduction is safe to apply to anything, whereas an alias is a judgement
  #? about one name.
  #?
  #? Separator runs are collapsed rather than converted one-for-one, because
  #? `zen--twilight` and `zen-twilight` naming the same thing is far more
  #? likely than a name whose meaning turns on a doubled dash.
  slugify = text: let
    lower = toLower text;
    #? One separator per boundary. Each substitution is its own call:
    #? `replaceStrings` takes lists of equal length, or a single replacement
    #? broadcast against many patterns -- and `[4 patterns] -> [1]` is
    #? neither, so folding per character is the only shape it accepts.
    spaced =
      foldl' (
        previous: separator: replaceStrings [separator] ["-"] previous
      )
      lower ["_" "." " " "+"];
    #? Runs of dashes are then collapsed. `replaceStrings` is literal, not
    #? regular, so one pass only ever shortens a run by a single dash --
    #? hence three passes, enough for any run a name realistically has. An
    #? over-long run is left partly collapsed rather than rejected: it is
    #? still a valid name, and capping the passes would make the result
    #? depend on how many dashes the author happened to type.
    squashed = foldl' (previous: _: replaceStrings ["--"] ["-"] previous) spaced [1 2 3];
    #? Leading and trailing separators are noise, so both ends are stripped
    #? *after* collapsing -- otherwise `-a-` and `a` would not reduce alike.
    #? Both strips are guarded on emptiness: a name of nothing but
    #? separators collapses to the empty string, which has no first or last
    #? character to inspect.
    dropLeading =
      if squashed == ""
      then ""
      else if substring 0 1 squashed == "-"
      then substring 1 (stringLength squashed) squashed
      else squashed;
    dropTrailing = let
      last = stringLength dropLeading;
    in
      if dropLeading == ""
      then ""
      else if substring (last - 1) last dropLeading == "-"
      then substring 0 (last - 1) dropLeading
      else dropLeading;
  in
    dropTrailing;

  #? Whether two names denote the same thing once their shape is normalised.
  sameName = left: right: slugify left == slugify right;

  #? Normalise a list and drop the duplicates that normalisation created, so
  #? a user declaring both `zen-twilight` and `zen_twilight` gets one entry
  #? rather than two attempts at the same package.
  uniqueNames = names: unique (map slugify names);
  #? Names that do not mean what they look like, and where each really lives.
  #?
  #? Distinct from `slugify`, which only reduces the *shape* of a name and is
  #? safe to apply to anything. An alias is a judgement about one specific
  #? name: it says a name in a spec is served by something with a different
  #? name elsewhere. `hermes` is the clearest case -- the user says `hermes`,
  #? and there is no package by that name in nixpkgs; the agent is published
  #? as `hermes-agent`, and the *desktop* variant as `hermes-desktop`, which is
  #? a different derivation again.
  #?
  #? Aliases are keyed by the slugified request, so `hermes`, `Hermes` and
  #? `hermes-agent` all reach the same entry. Values are `{source, name}`:
  #? which pool to look in, and what to call it there. `source` is the registry
  #? name, because a package can come from nixpkgs, from a fetched flake, or
  #? from a package-set function -- and guessing wrong is exactly the failure
  #? an alias table exists to prevent.
  #?
  #? `variant` names a derivation within that package rather than the package
  #? itself, for sources that publish one package under several shapes.
  #? `source` is the registry name, so a consumer can find the input it must
  #? resolve the name against. `hermes-agent` is upstream (NousResearch) and is
  #? preferred over the same package re-published by `llm-agents`, so the alias
  #? points at the upstream source rather than the collection.
  aliases = {
    hermes = {
      source = "hermes-agent";
      name = "default";
      description = "the agent itself; the user says 'hermes'";
    };

    hermes-desktop = {
      source = "hermes-agent";
      name = "desktop";
      description = "the desktop application";
    };

    #? A user asking for a *variant* says the product and the channel. Zen
    #? publishes these as bare keys of its package-set function -- `twilight`,
    #? `beta` -- not as packages named after themselves, so there is no
    #? `zen-twilight` to find anywhere. The alias is the only thing that can
    #? carry "twilight, from zen" into a lookup.
    #?
    #? `source` is `zen-browser` to match the registry's package-set entry, which
    #? is the key `mkSets` files these derivations under.
    zen-twilight = {
      source = "zen-browser";
      name = "twilight";
      description = "Zen Browser, twilight channel";
    };

    zen-beta = {
      source = "zen-browser";
      name = "beta";
      description = "Zen Browser, beta channel";
    };

    zen = {
      source = "zen-browser";
      name = "default";
      description = "Zen Browser, release channel";
    };

    #? nixpkgs *throws* on `python` rather than omitting it -- an intentional
    #? error, since it used to mean Python 2 and silently shadowing the
    #? interpreter is worse than failing. A resolver searching pools cannot
    #? distinguish "absent" from "present but throwing", so the requested spelling
    #? is redirected here rather than left to hit the throw.
    #?
    #? `source = "pkgs"` because this is a rename within nixpkgs, not a move to
    #? another source.
    python = {
      source = "pkgs";
      name = "python3";
      description = "nixpkgs throws on a bare `python`; the intent is python3";
    };

    #? nixpkgs has a `chatgpt`, but it is `aarch64-darwin` only. On x86_64 the
    #? attribute exists and evaluating it fails, which a pool search reads as
    #? *found* -- so the resolver never reaches a source that can actually build
    #? it. The alias is the only place that judgement can live.
    chatgpt = {
      source = "llm-agents";
      name = "chatgpt";
      description = "nixpkgs' chatgpt is darwin-only; llm-agents builds it for Linux";
    };

    codex = {
      source = "llm-agents";
      name = "codex";
      description = "OpenAI Codex CLI, from llm-agents";
    };
  };

  #? The alias for a request, or `null` when the name needs no translation.
  #?
  #? Matching is on the slugified form so an alias is found however the user
  #? cased or separated it.
  aliasOf = name: let
    found = filter (entry: slugify entry == slugify name) (attrNames aliases);
  in
    if found == []
    then null
    else aliases.${head found};
in {
  inherit (builtins) hashString;
  inherit
    capitalize
    showList
    showPath
    mkPath
    mkPathLiteral
    slugify
    sameName
    uniqueNames
    aliases
    aliasOf
    ;
}
