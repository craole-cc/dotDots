{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) substring;
  inherit (lib.types)
    attrs
    path
    nullOr
    str
    either
    ;
  inherit (config.dot.sources) user home-manager;
  inherit (config.dot.libraries.filesystem)
    listPaths
    mkSource
    nullOrPathOf
    githubPathOf
    ;
  inherit (config.dot.modules.host.current) stateVersion;
in
{
  options.dot.sources = {

    user = with user; {
      configuration = mkOption { default = mkSource ../configurations; };
      context = mkOption { default = mkSource ../components/context; };
    };

    home-manager = with home-manager; {
      enable = mkEnableOption "Home-Manager Source";

      enableUnstable = mkEnableOption "Use Unstable Packages" // {
        default = true;
      };

      channel = mkOption {
        description = "The channel of the home-manager source";
        default = {
          path = nullOrPathOf <home-manager/nixos>;
        };
        type = attrs;
      };

      repository =
        with repository;
        mkOption {
          description = "The repository of the home-manager source";
          default =
            let
              owner = "nix-community";
              repo = "home-manager";
              rev = if enableUnstable then "master" else "release-${stateVersion}";
              sha256 =
                let
                  key = {
                    master = "1vfaiyh5k634m5jmc2fj8k2fzy85f7v5l55zhi2kx200sy3icgsb";
                    "release-23.11" = "1fd7631c8f5l1ma5ksn8i57xhx5iiwqw9mwf5cxis3hmq7z9wpk0";
                    "release-24.05" = "0l3pcd38p4iq46ipc5h3cw7wmr9h8rbn34h8a5a4v8hcl21s8r5x";
                  };
                in
                key.${rev};
              fetched = githubPathOf {
                inherit
                  owner
                  repo
                  rev
                  sha256
                  ;
              };
              path = nullOrPathOf (fetched + "/nixos");
            in
            {
              inherit
                owner
                repo
                rev
                sha256
                fetched
                path
                ;
            };
          type = attrs;
        };

      default = mkOption {
        description = "The path to the home-manager source";
        default = (if channel != null then channel else repository).path;
        type = nullOr (either path str);
      };
    };
  };
}
