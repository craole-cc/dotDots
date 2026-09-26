{host, lix, pkgs, user, ...}: let
  packageNames = lix.lists.unique (
    user.packages.common
    ++ user.packages.coding
    ++ user.packages.launchers
    ++ user.packages.shells
  );

  packages = lix.lists.filter
    (name: pkgs ? ${name})
    (lix.lists.map (name: pkgs.${name}) packageNames);
in {
  home.stateVersion = host.stateVersion;
  home.username = user.name;
  home.homeDirectory = user.paths.roots.home;

  home.packages = packages;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = user.git.name;
        email = user.git.email;
      };
    } // (user.git.settings or {});
  };
}
