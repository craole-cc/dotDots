{host, ...}: let
  primary = host.principals.primary;
in {
  programs = {
    bash.enable = true;
    dconf.enable = true;
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        user = {
          name = primary.git.name;
          email = primary.git.email;
        };
        init.defaultBranch = "main";
        safe.directory = [host.paths.roots.src];
        url."https://github.com/".insteadOf = ["gh:" "github:"];
      } // (primary.git.settings or {});
    };
    nh = {
      enable = true;
      clean.enable = true;
      flake = host.paths.roots.src;
    };
    nix-index.enable = true;
    nix-index-database = {
      enable = true;
      comma.enable = true;
    };
    starship.enable = true;
  };
}
