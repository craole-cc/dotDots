{lix, ...}: {
  imports = lix.filesystem.importers.importAllPaths ./.;

  config = {
    programs.regreet = {
      enable = true;
    };
    # services = {
    #   displayManager.plasma-login-manager.enable = true;
    # };
  };
}
