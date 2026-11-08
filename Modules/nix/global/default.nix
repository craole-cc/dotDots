{
  lix,
  pkgs,
  ...
} @ passthru: let
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.transformation) reverseList;
  inherit (pkgs) mkShell;

  args = recursiveUpdate passthru (import ./shared passthru);

  shells = let
    dir = ./.;
    exclude = ["shared" "fmt" "ai"];
  in
    (importAllNamed {inherit args dir exclude;}).value;

  inherit (args) fetch mkName print;
  inherit (shells) core;

  # ai = import ./ai {
  #   inherit args;
  #   inherit core;
  # };
  # shellsWithAi = shells // {inherit ai;};
  shellsWithAi = shells;

  build =
    mapAttrs (
      name: cfg:
        mkShell {
          name = mkName name;
          env = core.env // (cfg.env or {});
          #? Core is the base layer. Every other shell runs core's whole
          #? shellHook (runtime, binit, yazi, starship, fetch) before its own.
          shellHook =
            if name == "core"
            then cfg.shellHook or ""
            else core.shellHook + (cfg.shellHook or "");
          packages = (cfg.packages or []) ++ core.packages;
        }
    )
    shells;

  devShells =
    build
    // {
      default = build.core;

      # inherit
      # (ai.devShells)
      # ai
      # "ai-headroom"
      # "ai-hermes"
      # "ai-hermes-hindsight"
      # "ai-hermes-hindsight-headroom-9router"
      # "ai-hermes-hindsight-headroom-omniroute"
      # "ai-hermes-hindsight-9router"
      # "ai-hermes-hindsight-omniroute"
      # "ai-hermes-mem0"
      # "ai-hindsight"
      # "ai-mem0"
      # "ai-9router"
      # "ai-omniroute"
      # ;

      fmt = args.treefmt.devShell;

      full = mkShell {
        name = mkName "full";

        env =
          foldl' (acc: name: acc // (shellsWithAi.${name}.env or {}))
          (foldl' (acc: cfg: acc // (cfg.env or {})) {} (attrValues shellsWithAi))
          (reverseList ["core"]);

        shellHook =
          core.runtimeHook
          + ''
            ${fetch.name} --full
            ${print.info "Full profile - every devShell package installed"}
          '';

        packages = concatMap (cfg: cfg.packages or []) (attrValues shellsWithAi);
      };
    };
in {
  inherit (args) apps formatter checks;
  inherit devShells;
}
