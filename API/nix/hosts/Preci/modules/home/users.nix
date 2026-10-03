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
  inherit (lix.attrsets) attrValues getAttr listToAttrs;
  inherit (lix.lists) map;

  #? The registry's Home Manager module group, flattened to the list a
#? profile's `imports` expects.
  homeModules = attrValues lix.modules.home;

  mkUser = user: {
    inherit (user) name;
    value = {
      _module.args = {
        user = getAttr user.name context.data.principals;
      };

      imports =
        [
          ./user.nix
          ./secrets.nix
        ]
        ++ homeModules;
    };
  };
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    #? `context` is the resolution bundle: `user.nix` reads the per-user
    #? package selection out of it, so it must reach every profile.
    extraSpecialArgs = {
      inherit host context lix inputs;
    };

    users = listToAttrs (map mkUser host.principals.all);
  };
}