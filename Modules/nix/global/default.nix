args: let
  inherit (args) lix pkgs;
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (pkgs) mkShell;
  shared = import ./shared args;

  #> Build the final derivations
  shells =
    mapAttrs (
      name: cfg:
        mkShell {
          name = "${args.cfg.name}-${name}";
          env = cfg.env or {};
          shellHook = cfg.shellHook or "";
          packages = cfg.packages or [];
        }
    )
    #> Every folder directly under this directory with a default.nix,
    #> except `shared` (formatters/packages, not a shell), keyed by
    #> folder name, each called with only the args it declares
    (importAllNamed {
      args = args // shared;
      dir = ./.;
      exclude = ["shared"];
    });
in {
  inherit (shared) formatter checks;
  devShells = shells // {default = shells.core;};
}
