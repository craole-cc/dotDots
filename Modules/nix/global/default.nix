global: let
  inherit (global) lix pkgs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.attrsets.access) attrNames attrValues;
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

      fmt = args.devShell.overrideAttrs (old: let
        treefmt = args.sources.treefmt;

        treefmtVersion = let
          rev = treefmt.revision;
        in
          if rev != null
          then "$(${treefmt.paths.exe} --version | ${pkgs.gawk}/bin/awk '{print $2}') (${rev})"
          else "unknown";
      in {
        shellHook =
          (old.shellHook or "")
          + ''
            ${print.title "Formatter Environment"}
            ${print.table {
              columns = ["Formatter" "Version"];
              rows =
                [["treefmt" treefmtVersion]]
                ++ map (name: [
                  name
                  (args.programs.${name}.version or "unknown")
                ]) (attrNames args.programs);
            }}
          '';
      });

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
