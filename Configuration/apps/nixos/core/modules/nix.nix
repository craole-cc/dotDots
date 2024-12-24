{
  specialArgs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs) host users;
  inherit (host) stateVersion system;
  inherit (lib.attrsets) attrNames;
  userList = attrNames users;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
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
      ] ++ userList;
    };
    extraOptions = ''
      download-buffer-size = 4096
    '';
  };

  nixpkgs = {
    hostPlatform = system;
  };

  system = { inherit stateVersion; };
}
