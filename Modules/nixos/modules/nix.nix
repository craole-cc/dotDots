{
  alpha,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "@wheel"
        alpha
      ];
    };
    extraOptions = ''
      download-buffer-size = 524288000 #TODO: Does this work now
    '';
  };
}
