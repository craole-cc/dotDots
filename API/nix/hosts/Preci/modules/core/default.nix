#? This host''s NixOS modules, plus the registry entries `context.modules`
#? enabled for it.
#?
#? `context` arrives through `_module.args`, which a module does see -- unlike
#? `modules/default.nix`, which is a plain function called with `{lix}` while
#? the root file is being evaluated and therefore has no access to it. So the
#? gate belongs here, in a module, rather than in the root or in the tree root.
#?
#? Only the *core* group joins the NixOS tree. The `home` group is Home Manager
#? modules and the NixOS evaluator rejects them -- importing sops''s HM module
#? here collides with its own NixOS module on `sops.gnupg.home`. Those go into
#? each principal''s profile instead, in `modules/home/users.nix`.
{context, ...}: {
  imports =
    context.modules.imports.core
    ++ [
      ./boot
      ./environment
      ./hardware
      ./networking
      ./programs
      ./secrets
      ./security
      ./services
      ./users
    ];
}
