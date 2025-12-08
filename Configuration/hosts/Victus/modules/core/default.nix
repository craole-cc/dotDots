{...}: {
  imports = [
    ./environment
    ./programs
    ./services
    ./themes

    ./audio.nix
    ./boot.nix
    ./filesystem.nix
    ./localization.nix
    ./networking.nix
    ./security.nix
    ./system.nix
    ./users.nix
  ];
}
