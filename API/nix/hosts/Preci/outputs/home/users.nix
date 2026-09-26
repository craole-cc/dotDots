{host, lix, inputs, resolved, ...}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit host lix inputs;
    };

    users = lix.attrsets.listToAttrs (lix.lists.map (user: {
      name = user.name;
      value = {
        _module.args = {
          user = resolved.principals.${user.name};
        };
        imports = [./user.nix];
      };
    }) host.principals.all);
  };
}
