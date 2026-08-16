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
  inherit (shared) mkName;

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
  inherit (shared) formatter checks;
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
          ${core.shellHook}
          printf '\n>> Full profile - every devShell package installed <<\n\n'
        '';
        packages = concatMap (cfg: cfg.packages or []) (attrValues shells);
      };
    };
}
