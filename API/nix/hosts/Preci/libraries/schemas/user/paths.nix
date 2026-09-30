{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate mapAttrs;
  inherit (lib.strings) concatStringsSep;
  inherit (lix.debug) requireNonEmpty;

  default = {
    roots = {
      home = null; # derived from name below, unless overridden
      var = "/var";
    };
    stems = {
      pictures = {
        root = "home";
        path = ["Pictures"];
      };
      downloads = {
        root = "home";
        path = ["Downloads"];
      };
      avatars = {
        root = "home";
        path = ["Pictures" "Avatars"];
      };
      wallpapers = {
        root = "home";
        path = ["Pictures" "Wallpapers"];
      };
    };
  };

  resolve = {
    args ? {},
    paths ? args.paths or {},
    name ? args.name or null,
    context ? "resolve user paths (user \"${toString name}\")",
  }: let
    merged = recursiveUpdate default paths;

    home =
      if merged.roots.home != null
      then merged.roots.home
      else
        assert requireNonEmpty {
          inherit context;
          path = ["name"];
          set = {inherit name;};
        }; "/home/${toString name}";

    roots = merged.roots // {inherit home;};

    joinStem = stemName: stem:
      if roots ? ${stem.root}
      then concatStringsSep "/" ([roots.${stem.root}] ++ stem.path)
      else throw "${context}: stem '${stemName}' references unknown root '${stem.root}' (known roots: ${concatStringsSep ", " (builtins.attrNames roots)})";

    resolvedStems = mapAttrs joinStem merged.stems;
  in
    merged
    // {
      inherit roots;
    }
    // resolvedStems;
in {inherit default resolve;}
