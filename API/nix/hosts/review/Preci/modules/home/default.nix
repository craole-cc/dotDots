#? Home Manager wiring for this host's principals.
#?
#? Declares the `home-manager.users` entry point. `./programs` and `./secrets`
#? are imported per-principal from here, so they are deliberately not listed in
#? any host-level import list.
#?
#? `context.modules.imports.home` is the registry's gated Home Manager module
#? group. Those are imported *per user*, inside each profile, not into the NixOS
#? module tree: `sops.homeManagerModules` and `hermes.homeManagerModules` are
#? Home Manager modules and the NixOS evaluator would reject them.
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

  #? One `home-manager.users` entry for a principal declared on this host.
  #?
  #? The `home` options sit inside the per-user value because they describe one
  #? user's profile; there is no host-wide `home-manager.home`.
  mkUser = user: let
    inherit (user) name;
    # principal = getAttr user.name context.principals;
  in {
    inherit name;
    value = {
      # _module.args.user = principal;
      _module.args = {inherit user;};

      imports =
        context.modules.imports.home
        ++ [
          ./programs
          ./services
          ./secrets
        ];

      home = {
        inherit (host) stateVersion;
        username = user.name;
        homeDirectory = user.paths.roots.home;
        packages = context.packages.home.${name}.packages;
      };
    };
  };
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit host context lix inputs;};
    users = listToAttrs (map mkUser context.principals.defined);
  };
}
