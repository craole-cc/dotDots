{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
let

  home-manager =
    let
      channel = __tryEval <home-manager>;
      tarball = fetchTarball {
        url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
        sha256 = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk6";
      };
    in
    "${if channel.success then channel.value else tarball}/nixos";

  stylix =
    let
      repo = pkgs.fetchFromGitHub {
        owner = "danth";
        repo = "stylix";
        rev = "master";
        sha256 = "W9Y/+K4L7JcF5xcXO4MVGQk/0DgzHrp/IjlHyLeYExY=";
      };
    in
    "${repo}/nixos";
in
#   home-manager =
#     let
#       channel = __tryEval <home-manager/pop>;
#       repo = pkgs.fetchFromGitHub {
#         owner = "nix-community";
#         repo = "home-manager";
#         rev = "master";
#         sha256 = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk6";
#       };
#     in
#     "${if channel.success then channel.value else (import repo)}/nixos";
#   stylix =
#     let
#       repo = pkgs.fetchFromGitHub {
#         owner = "nix-community";
#         repo = "home-manager";
#         rev = "master";
#         sha256 = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk6";
#       };
#     in
#     "${repo}/nixos";
#   stylix = rec {
#     channel = __tryEval <stylix>;
#     tarball = pkgs.fetchFromGitHub {
#       owner = "danth";
#       repo = "stylix";
#       rev = "...";
#       sha256 = "...";
#     };
#     path = "${if channel.success then channel.value else tarball}/nixos";
#   };

{
  imports = [
    home-manager
    ./home-manager.nix
    ./stylix.nix
    # stylix
    # stylix
  ];
}
