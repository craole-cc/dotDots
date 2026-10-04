{lib ? import <nixpkgs/lib>, ...}: let
  lix = import ./libraries {inherit lib;};
  specs = import ./specs;
  host = lix.schemas.host.mkHost specs;
  context = import ./context {inherit lix host;};
  modules = import ./modules {inherit lix;};
in {
  #? The gated registry groups join the tree here rather than in
  #? `modules/core/default.nix`, which cannot read a module argument from its
  #? own `imports` without recursing -- see the note there.
  #?
  #? Only the *core* group. The `home` group is Home Manager modules and the
  #? NixOS evaluator rejects them: importing sops'' HM module here collides with
  #? its own NixOS module on `sops.gnupg.home`. Those are imported per principal
  #? in `modules/home/default.nix`.
  imports =
    modules.imports
    ++ context.modules.imports.core;

  _module.args = {inherit lix host context specs;};
}
