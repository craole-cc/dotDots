#? This host''s NixOS modules.
#?
#? The registry entries `context.modules` enabled for this host are *not* listed
#? here. They are added in the root `default.nix`, because they cannot be a
#? module argument read from `imports`:
#?
#? `context` reaches modules through `_module.args`, and reading a module
#? argument inside `imports` forces `_module.args` -- which is declared by the
#? same root attrset whose `imports` is being evaluated. That is circular, and
#? NixOS reports it as `infinite recursion encountered` with a note about
#? referencing `config` in `imports`. The root file has `context` as an ordinary
#? `let` binding, so reading it there needs nothing from the module system.
#?
#? Only this host''s own modules live in this directory.
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
      ./warnings.nix
    ];
}
