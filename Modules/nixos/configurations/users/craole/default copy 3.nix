{
  imports = [ ];
  home = {
    sessionVariables.READER = "bat";
  };
  programs = {
    bat.enable = true;
    btop.enable = true;
    helix.enable = true;
    git = {
      enable = true;
      userName = "Craole";
      userEmail = "32288735+Craole@users.noreply.github.com";
      lfs.enable = true;
    };

  };
}
