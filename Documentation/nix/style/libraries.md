# Library Style

This guide covers the style that shows up in `Libraries/nix`.

`Libraries/nix` is the repo’s reusable Nix foundation, so library code should look like a small, structured standard library rather than a loose bundle of helpers.

## Typical characteristics

Library code in `Libraries/nix` tends to be:

- highly decomposed into small modules
- documented with long-form docstrings
- exported through a structured `__rootAliases` surface
- tested inline with `__tests`
- validated with helper predicates before doing real work

## Example: constructor with validation

```nix
mkBool = {
  field,
  trueKey,
  falseKey,
  set,
}:
  if !isString field then throw "field must be a string"
  else if !isString trueKey then throw "trueKey must be a string"
  else if !isString falseKey then throw "falseKey must be a string"
  else if trueKey == falseKey then throw "keys must be different"
  else {
    ${trueKey} = withFlag { inherit field set; };
    ${falseKey} = withoutFlag { inherit field set; };
  };
```

What this shows:

- explicit named record args
- guard clauses before the real result
- caller-controlled output keys
- no silent coercion

## Library export shape

Library modules commonly expose multiple surfaces together:

- `__docs` for documentation
- `__tests` for inline tests
- `__rootAliases` for public aliases
- the function or namespace itself for direct use

This keeps the library discoverable and makes the public API visible in one place.

## Library behavior to prefer

- validate inputs before constructing outputs
- prefer explicit dependency injection over hidden globals
- keep helper functions close to the logic that uses them
- make transformation steps visible and composable
- use `tree.store.*` for repo-aware paths

## What to avoid

- sprawling utility files with unrelated helpers
- silent fallbacks that hide invalid inputs
- exporting only one deep implementation detail when a small public API would be clearer
- duplicating data that belongs in `API/nix`
