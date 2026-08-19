global: let
  inherit (global) lix pkgs;
  inherit (lix.attrsets.access) attrNames attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.lists.access) elemAt;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.transformation) filter reverseList sort;
  inherit (lix.lists.predicates) elem;
  inherit (pkgs) mkShell;

  local = import ./shared global;
  args = recursiveUpdate global local;

  shells = importAllNamed {
    inherit args;
    dir = ./.;
    exclude = ["shared" "fmt" "lib.nix" "ai"];
  };

  inherit (args) fetch mkName print;
  inherit (shells) core;

  build =
    mapAttrs (
      name: cfg:
        mkShell {
          name = mkName name;
          env = core.env // (cfg.env or {});
          shellHook = cfg.shellHook or "";
          packages =
            (
              optionals
              ((name == "extras") || (name == "hermes"))
              core.packages
            )
            ++ cfg.packages or [];
        }
    )
    shells;
in {
  inherit (args) apps formatter checks;

  devShells =
    build
    // {
      default = build.core;
      fmt = args.treefmt.devShell;
      # fmt = args.devShell.overrideAttrs (old: let
      #   inherit (args.sources) treefmt;

      #   version = let
      #     rev = treefmt.revision;
      #   in
      #     if rev != null
      #     then "$(${treefmt.paths.exe} --version | ${pkgs.gawk}/bin/awk '{print $2}') (${rev})"
      #     else "unknown";

      #   programNames = attrNames args.programs;
      #   fromPrograms =
      #     map (name: [name (args.programs.${name}.version or "unknown")])
      #     programNames;

      #   fromPackages =
      #     map (pkg: [(pkg.pname or pkg.name or "unknown") (pkg.version or "unknown")])
      #     (filter (
      #         pkg: let
      #           n = toLower (pkg.pname or pkg.name or "");
      #         in
      #           n
      #           != ""
      #           && n != "treefmt"
      #           && n != "git"
      #           && !(elem n (map toLower programNames))
      #       )
      #       args.packages);

      #   formatters = let
      #     rest = fromPrograms ++ fromPackages;
      #     sorted =
      #       sort
      #       (a: b: (elemAt a 0) < (elemAt b 0))
      #       rest;
      #   in
      #     [["treefmt" version]] ++ sorted;
      # in {
      #   shellHook =
      #     (old.shellHook or "")
      #     + ''
      #       ${print.title "Formatter Environment"}
      #       ${print.table {
      #         columns = ["Formatter" "Version"];
      #         rows = formatters;
      #       }}
      #     '';
      # });

      full = mkShell {
        name = mkName "full";

        env =
          foldl'
          (acc: name: acc // (shells.${name}.env or {}))
          #> Baseline: every shell's env folded in normal (attrValues) order.
          (foldl' (acc: cfg: acc // (cfg.env or {})) {} (attrValues shells))
          (reverseList ["core" "hermes"]);

        shellHook = ''
          ${fetch.name} --full
          ${print.info "Full profile - every devShell package installed"}
        '';

        packages = concatMap (cfg: cfg.packages or []) (attrValues shells);
      };
    };
}
