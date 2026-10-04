#? Home Manager wiring for this host's principals.
#?
#? `users.nix` declares the `home-manager.users` entry point. `user.nix` and
#? `secrets.nix` are imported per-principal from it, so they are deliberately
#? not listed here.
#?
#? `lix.modules.home` is the registry's Home Manager module group. Those are
#? imported *per user*, inside each profile, not into the NixOS module tree:
#? `sops.homeManagerModules` and `hermes.homeManagerModules` are Home Manager
#? modules and the NixOS evaluator would reject them.
#?
#? Per-principal data (profile, theme, keybindings, encrypted secrets) lives
#? under `specs/users/<name>/`, so each principal is wired from its own spec
#? rather than from a host-level `users/` tree.
{
  context,
  host,
  lix,
  inputs,
  ...
}: let
  inherit (lix.attrsets) getAttr listToAttrs;

  #? The same gate the NixOS tree gets, applied to the Home Manager group: only
  #? the registry entries this host asked for. Without it every HM module would
  #? be pulled into every profile, and a request would be indistinguishable from
  #? an always-on module.
  #?
  #? Taken from `context.modules.imports.home` rather than filtered again here --
  #? that record is already gated, so re-deriving it would be a second place free
  #? to disagree with the NixOS side.
  enabled = context.modules.imports.home;

  mkUser = user: {
    inherit (user) name;
    value = {
      _module.args.user = getAttr user.name context.principals;
      imports = enabled ++ [./user.nix ./secrets.nix];
    };
  };
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit host context lix inputs;};
    users = listToAttrs (map mkUser host.principals.defined);
  };
}
