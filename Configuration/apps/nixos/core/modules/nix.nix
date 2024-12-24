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
    download-buffer-size = 1024 * 1024 * 1024 * 4;
    settings = {
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
  };

  nixpkgs = {
    hostPlatform = system;
  };

  system = { inherit stateVersion; };
}
