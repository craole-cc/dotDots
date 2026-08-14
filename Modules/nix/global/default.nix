args: let
  inherit (args) lix pkgs;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.construction) optionals;
  inherit (pkgs) mkShell;
  shared = import ./shared args;

  #> Every folder directly under this directory with a default.nix,
  #> except `shared` (formatters/packages, not a shell), keyed by
  #> folder name, each called with only the args it declares
  shells = importAllNamed {
    args = args // shared;
    dir = ./.;
    exclude = ["shared"];
  };
  base = {
    packages = shells.core.packages or [];
  };

  #> Build the final derivations. Every shell's packages extend core's -
  #> core itself is untouched (its own packages already ARE corePackages).
  #> env/shellHook are never merged across shells - each writes its own.
  build =
    mapAttrs (
      name: cfg:
        mkShell {
          name = "${args.cfg.name}-${name}";
          env = cfg.env or {};
          shellHook = cfg.shellHook or "";
          packages =
            cfg.packages or []
            ++ (
              optionals
              ((name == "extras") || (name == "hermes"))
              base.packages
            )
            ++ [];
        }
    )
    shells;
in {
  inherit (shared) formatter checks;
  devShells = build // {default = build.core;};
}
