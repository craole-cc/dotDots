#? The host module tree.
#?
#? Only this host''s own modules are listed here. The registry groups -- NixOS
#? (`lix.modules.core`) and Home Manager (`lix.modules.home`) -- are *gated*
#? through `context.modules`, which has already decided which registry entries
#? this host asked for, and are added in the root `default.nix` where that
#? record is in scope.
#?
#? They cannot be listed here: `modules/default.nix` is not a module. It is a
#? plain function called with `{lix}` while the root file is being evaluated, so
#? it has no access to `_module.args` and therefore no access to `context`.
#? Reading it here would fail with "called without required argument
#? 'context'" rather than quietly importing the wrong thing.
#?
#? The host''s own SOPS rules live in its `.sops.yaml`, not in this tree, so
#? there is no registry entry for them -- they are host-private and must not
#? come from the shared flake registry. The module that reads them is
#? `./core/secrets.nix`, alongside every other host module.
{lix, ...}: {
  imports = [
    ./core
    ./home
  ];
}
