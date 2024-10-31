{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.system) stateVersion;
  inherit (config) dot;
in
{
  options.dot.sources.home-manager = with config.dot.sources.home-manager; {
    enable = mkEnableOption "Home-Manager Source";

    enableUnstable = mkEnableOption "Use Unstable Packages" // {
      default = true;
    };

    source = mkOption {
      description = "The path to the home-manager source";
      default =
        let
          sha256 = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk0";
          rev = if enableUnstable then "master" else "release-${stateVersion}";
          owner = "nix-community";
          repo = "home-manager";
          channel = tryEval <home-manager>;
          tarball = fetchTarball {
            #   url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
            url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
            inherit sha256;
          };
          repository = pkgs.fetchFromGitHub {
            inherit
              owner
              repo
              rev
              sha256
              ;
          };
        in
        repository + "/nixos";
      # "${if channel.success then channel.value else repository}/nixos";
      # type = path;
    };
  };
}
