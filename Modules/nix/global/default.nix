{
  inputs,
  lix,
  paths,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.traversal) importAllNamed;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (pkgs) mkShell;

  args = import ./shared {
    inherit inputs lix paths pkgs;
    cfg = {
      name = "dotDots";
      version = "2.0.0";
      cache = ".cache";
      prefix = ".";
      allowAI = true;
    };
  };
in {
  inherit (args) formatter checks;
  devShells = let
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
      #> Import every subdirectory under ./shells (core, ai, media, ...)
      #> that has a default.nix, keyed by folder name, each called with only
      #> the subset of `args` it declares as parameters
      (importAllNamed {
        inherit args;
        dir = ./shells;
      });
  in
    shells // {default = shells.core;};
}
