# {
#   imports = [ ./lib ];
#   # DOTS.alpha = "craole";
#   # DOTS.Hosts.dbook.enable = true;
# }

{ config, pkgs, lib, ... }:

let
  dib  = import ./lib { inherit lib pkgs; };
in {
  # Example usage of a function from your custom library
  services.home-assistant.config = {
    githubUserData = dib.fetchGitHubUser "someusername";
  };

  # Example usage of a utility function
  environment.systemPackages = [
    (if myLib.isEmpty "example" then pkgs.somePackage else pkgs.otherPackage)
  ];

  # Other configurations...
}
