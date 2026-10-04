#? The host module tree.
#?
#? `lix.modules.core` and `lix.modules.home` are the registry's module groups,
#? each an attrset keyed by module name. `attrValues` flattens a group into the
#? list `imports` expects, preserving the registry's own order.
#?
#? The host's own SOPS rules live in its `.sops.yaml`, not in this tree, so
#? there is no registry entry for them -- they are host-private and must not
#? come from the shared flake registry. The module that reads them is
#? `./core/secrets.nix`, alongside every other host module.
{lix, ...}: {
  imports =
    (lix.attrsets.attrValues lix.modules.core)
    ++ [./core ./home];
}
