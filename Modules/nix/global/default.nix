{
  cfg,
  lix,
  inputs,
  pkgs,
  names,
  paths,
  ...
}: let
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.attrsets.access) attrValues;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.construction) optionals;
  inherit (lix.lists.transformation) reverseList;
  inherit (pkgs) mkShell;

  args = {
    inherit cfg lix pkgs inputs;
    src = {
      name = names.src;
      path = paths.src.store;
    };
  };

  shared = import ./shared args;
  shells = importAllNamed {
    args = args // shared;
    dir = ./.;
    exclude = ["shared" "ai"];
  };
  inherit (shells) core;

  build =
    mapAttrs (
      name: cfg:
        mkShell {
          name = shared.mkName name;
          env = core.env // cfg.env or {};
          shellHook = cfg.shellHook or "";
          packages =
            cfg.packages or []
            ++ (
              optionals
              ((name == "extras") || (name == "hermes"))
              core.packages
            )
            ++ [];
        }
    )
    shells;
in {
  inherit (shared) formatter checks;
  devShells =
    build
    // {
      default = build.core;
      full = mkShell {
        name = "${args.cfg.name}-full";
        env =
          foldl'
          (acc: name: acc // (shells.${name}.env or {}))
          #> Baseline: every shell's env folded in normal (attrValues) order.
          (foldl' (acc: cfg: acc // (cfg.env or {})) {} (attrValues shells))
          (reverseList ["core" "hermes"]);
        shellHook = ''
          ${core.shellHook}
          printf '\n>> Full profile - every devShell package installed <<\n\n'
        '';
        packages = concatMap (cfg: cfg.packages or []) (attrValues shells);
      };
    };
}
