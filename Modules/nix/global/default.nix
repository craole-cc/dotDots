global: let
  inherit (global) lix pkgs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.attrsets.access) attrValues;
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
    exclude = ["shared" "ai"];
  };

  inherit (args) fetch mkName;
  inherit (shells) core;

  build =
    mapAttrs (
      name: cfg:
        mkShell {
          name = mkName name;
          env = core.env // cfg.env or {};
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
  inherit (args) formatter checks;
  devShells =
    build
    // {
      default = build.core;
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
          printf '\n>> Full profile - every devShell package installed <<\n\n'
        '';
        packages = concatMap (cfg: cfg.packages or []) (attrValues shells);
      };
    };
}
