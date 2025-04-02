{
  dots,
  pkgs,
  ...
}:
let
  hostName = "QBXL";
in
{
  environment.systemPackages = with pkgs; [
    nixd
    nixfmt-rfc-style
  ];
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
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
}
