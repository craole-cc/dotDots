{ config, ... }:
let
  inherit (config) DOTS;
  inherit (DOTS) location;
  stateVersion = "24.05";

in
{
  system = {
    inherit stateVersion;
  };
  time = {
    inherit (location) timeZone;
  };
  i18n = {
    inherit (location) defaultLocale;
  };
  location = {
    inherit (location) longitude latitude;
    provider =
      let
        inherit (config.location) latitude longitude;
      in
      if (latitude == null || longitude == null) then "geoclue2" else "manual";
  };
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 3d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [
        "big-parallel"
        "kvm"
        "recursive-nix"
        "nixos-test"
      ];
    };
  };
}
