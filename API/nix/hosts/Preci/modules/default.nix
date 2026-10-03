#? The host module tree.
#?
#? `lix.modules.core` and `lix.modules.home` are the registry's module groups,
#? each an attrset keyed by module name. `attrValues` flattens a group into the
#? list `imports` expects, preserving the registry's own order.
#?
#? `./secrets` is a local domain rather than a registry entry: it holds this
#? host's encrypted values and their SOPS rules, which are host-private and
#? must not come from the shared flake registry.
{lix, ...}: {
  imports =
    (lix.attrsets.attrValues lix.modules.core)
    ++ [
      ./core
      ./home
      ../secrets
    ];
}