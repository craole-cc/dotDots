{host, lix, inputs, ...}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = {
      inherit host lix inputs;
    };

    users = lix.attrsets.listToAttrs (lix.lists.map (user: {
      name = user.name;
      value = {
        _module.args = {inherit user;};
        imports = [./user.nix];
      };
    }) host.principals.all);
  };
}
