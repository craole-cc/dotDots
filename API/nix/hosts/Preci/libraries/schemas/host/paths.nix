{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.debug) requireNonEmpty;
  inherit (lix.strings) concatStringsSep;

  default = {
    roots = {
      src = null; # Must be set — the path to the flake. No sensible fallback.
      build = null; # The build point of the configuration. Falls back to src/API/nix/hosts/<name>.
    };
  };

  resolve = {
    paths ? args.paths or {},
    name ? args.name or null,
    context ? "resolve host paths (host \"${toString name}\")",
    ...
  } @ args: let
    merged = recursiveUpdate default paths;

    src = merged.roots.src;
    build =
      if merged.roots.build != null
      then merged.roots.build
      else concatStringsSep "/" [src "API" "nix" "hosts" (toString name)];
  in
    assert requireNonEmpty {
      inherit context;
      path = ["roots" "src"];
      set = {roots = {inherit src;};};
    };
      merged // {roots = merged.roots // {inherit src build;};};
in {inherit default resolve;}
