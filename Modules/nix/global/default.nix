global: let
  inherit (global) lix pkgs;
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.transformation) reverseList;
  inherit (pkgs) mkShell;

  local = import ./shared global;
  args = recursiveUpdate global local;

  shells = importAllNamed {
    inherit args;
    dir = ./.;
    exclude = [
      "shared"
      "fmt"
    ];
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
            (cfg.packages or [])
            ++ (
              optionals
              ((name != "minimal") && (name != "media"))
              core.packages
            );
        }
    )
    shells;

  ai = import ./ai {inherit args; inherit core;};

  devShells =
    build
    // {
      default = build.core;

      inherit (ai.devShells) ai "ai-router" "ai-memory" "ai-hermes";

      fmt = args.treefmt.devShell;

      full = mkShell {
        name = mkName "full";

        env =
          foldl'
          (acc: name: acc // (shells.${name}.env or {}))
          (foldl' (acc: cfg: acc // (cfg.env or {})) {} (attrValues shells))
          (reverseList ["core" "hermes"]);

        shellHook = ''
          ${fetch.name} --full
          ${print.info "Full profile - every devShell package installed"}
        '';

        packages = concatMap (cfg: cfg.packages or []) (attrValues shells);
      };
    };
in {
  inherit (args) apps formatter checks;
  inherit devShells;
}