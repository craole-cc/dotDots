{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  libraries = import ./lib {inherit lib;};
  inherit (libraries) lix;

  infrastructure = import ./infrastructure {
    lix = recursiveUpdate lix {
      host = lix.mkHost (import ./args.nix);
    };
  };
in {
  imports =
    (with lix.modules; [
      home-manager
      nix-index
      catppuccin
    ])
    ++ [./outputs];

  _module.args.lix = recursiveUpdate lix {inherit infrastructure;};
}
