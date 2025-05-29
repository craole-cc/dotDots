{dots, ...}: let
  hostName = "QBXL";
  stateVersion = "24.11";
in {
  networking = {
    inherit hostName;
    hostId = with builtins; substring 0 8 (hashString "md5" hostName);
  };
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
      dots.alpha
    ];
  };
  # nixpkgs.config.allowUnfree = true;
  system = {
    inherit stateVersion;
  };
}
