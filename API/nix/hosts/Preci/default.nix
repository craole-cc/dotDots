{lib ? import <nixpkgs/lib>, ...}: let
  lix = import ./libraries {inherit lib;};
  specs = import ./specs;
  host = lix.schemas.host.mkHost specs;
  context = import ./context {inherit lix host;};
  modules = import ./modules {inherit lix;};
in {
  #? The registry groups are gated here rather than in `modules/default.nix`,
  #? because that file is a plain function call with no access to `_module.args`
  #? -- and therefore none to `context`. This is the one place both the resolved
  #? modules and the gate are in scope, so it is where the two are combined.
  #?
  #? `context.modules.imports` already holds each group filtered to what was
  #? requested, so nothing here re-derives that decision.
  #? Only the *core* group joins the NixOS tree. The `home` group is Home Manager
  #? modules and the NixOS evaluator rejects them -- importing `sops`'s HM module
  #? here collides with its own NixOS module on `sops.gnupg.home`. They belong in
  #? each principal''s profile instead, which is where `modules/home/users.nix`
  #? puts them.
  imports = modules.imports ++ context.modules.imports.core;

  _module.args = {inherit lix host context specs;};
}
