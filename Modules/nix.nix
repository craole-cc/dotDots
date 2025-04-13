{ modulesPath, ... }:
# let
#   inherit (lib.attrsets) attrValues;
# in
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
      ];
    };
    extraOptions = ''
      download-buffer-size = 524288000 #TODO: Does this work now
    '';
  };

  # nixpkgs.overlays = attrValues packageOverlays;
}
