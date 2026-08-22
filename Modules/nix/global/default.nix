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
      "media"
      # "extras"
      "hermes"
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
            (optionals ((name == "extras") || (name == "hermes")) core.packages)
            ++ (cfg.packages or []);
        }
    )
    shells;

  aiShell = shells.ai;
  routerShell = aiShell.router;
  memoryShell = aiShell.memory;
  hermesShell = aiShell.agents.hermes;

  devShells =
    build
    // {
      default = build.core;

      ai = mkShell {
        name = mkName "ai";
        env = core.env // aiShell.env;
        inherit (aiShell) shellHook;
        packages = core.packages ++ aiShell.packages;
      };

      "ai-router" = mkShell {
        name = mkName "ai-router";
        env = core.env // routerShell.env;
        inherit (routerShell) shellHook;
        packages = core.packages ++ routerShell.packages;
      };

      "ai-memory" = mkShell {
        name = mkName "ai-memory";
        env = core.env // memoryShell.env;
        inherit (memoryShell) shellHook;
        packages = core.packages ++ memoryShell.packages;
      };

      "ai-hermes" = mkShell {
        name = mkName "ai-hermes";
        env = core.env // hermesShell.env;
        inherit (hermesShell) shellHook;
        packages = core.packages ++ hermesShell.packages;
      };

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
