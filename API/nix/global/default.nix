{
  names = {
    top = "_";
    lib = "lix";
  };

  # Paths that share the "hidden in a function signature" problem with
  # `names`.  `src` is intentionally absent — `tree`/`construct` use it to
  # resolve where `api/` itself lives, so it can never be sourced from here.
  paths = {
    libraries = "Libraries/nix";
  };
}
