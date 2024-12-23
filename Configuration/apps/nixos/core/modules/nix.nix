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
  userList = attrNames users;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
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
