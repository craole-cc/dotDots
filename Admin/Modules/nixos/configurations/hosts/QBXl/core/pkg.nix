{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    gitui
    nixd
    nixfmt-rfc-style
  ];

  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };

  services = {
    atuin.enable = true;
  };
}
