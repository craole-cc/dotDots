{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.debug) requireNonEmpty;
  inherit (lix.strings) mkPath;

  default = {
    roots = {
      src = null; # Must be set — the path to the flake. No sensible fallback.
      build = null; # The build point of the configuration. Falls back to src/API/nix/hosts/<name>.
    };
    #? Convenience alias for the repository root, as the monolith called it.
    #? Always derived: a second name for `roots.src` that could be set
    #? independently would be a second thing to keep correct.
    dots = null;
  };

  resolve = {
    paths ? args.paths or {},
    name ? args.name or null,
    context ? "resolve host paths (host \"${toString name}\")",
    ...
  } @ args: let
    merged = recursiveUpdate default paths;

    inherit (merged.roots) src;

    build =
      if merged.roots.build != null
      then merged.roots.build
      else mkPath src ["API" "nix" "hosts" (toString name)];

    roots = merged.roots // {inherit src build;};

    #? Derived locations, so no module has to assemble a path out of `../../`.
    #? `dots` is the repository root; the rest hang off `build`, which is this
    #? host's own tree.
    dots = roots.src;
    specs = mkPath build ["specs"];
    modules = mkPath build ["modules"];
    context = mkPath build ["context"];
    libraries = mkPath build ["libraries"];
    secrets = mkPath build ["secrets"];

    #? Per-principal data for this host: a user's specification directory, and
    #? the directory holding them all.
    principal = user: mkPath specs ["users" user];
    principals = mkPath specs ["users"];

    #? Cross-host user data, for credentials that follow a person to whatever
    #? machine they log into. Distinct from `principals` above, which is scoped
    #? to this host.
    users = mkPath src ["API" "nix" "users"];
  in
    assert requireNonEmpty {
      inherit context;
      path = ["roots" "src"];
      set = {roots = {inherit src;};};
    };
    #? `merged` already carries `roots` from `default`; the only thing added
    #? here is the derived `build` beside it. So `roots` is re-entered as an
    #? attribute of itself rather than inherited -- `inherit (roots) roots`
    #? would splice `src` and `build` to the *top level* and leave no `roots`
    #? to inherit from, which is what it did.
      merged
      // {
        inherit
          roots
          dots
          specs
          modules
          context
          libraries
          secrets
          principal
          principals
          users
          ;
      };
in {inherit default resolve;}
