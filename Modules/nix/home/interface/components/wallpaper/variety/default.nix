/*
Variety wallpaper manager, declaratively (home-manager module).

Layout
  default.nix  resolves shared context, packages and Variety paths
  options/     declares typed options, setting defaults and wallpaper sources
  outputs/     renders variety.conf, wraps the package and installs the profile

The parent wallpaper component composes these options and outputs under its engine configuration.
*/
{
  config,
  lix,
  paths,
  pkgs,
  wallpaper,
  toolkit,
  ...
} @ passthru: let
  mod = "variety";
  sub = "wallpaper";
  cfg = wallpaper.cfg.engines.${mod};
  context = wallpaper // {inherit mod sub cfg;};

  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.strings.transformation) escapeShellArg;
  paths' = let
    inherit (config.xdg) configHome;
    inherit (paths'.variety) profiles;
    under = root: mapAttrs (_name: stem: concat {inherit root stem;});
    variety = {
      profiles =
        (under configHome {
          main = "variety";
          extra = "variety-profiles";
        })
        // {
          active =
            if cfg.profile.name == null
            then profiles.main
            else if hasPrefix "/" cfg.profile.name
            then cfg.profile.name
            else
              concat {
                root = profiles.extra;
                stem = cfg.profile.name;
              };
        };
      scripts = under (concat {
        root = paths.store.lib.sh;
        stem = ["interface" "wallpaper"];
      }) {varietyctl = "varietyctl";};
      files = under cfg.profile.path {
        config = "variety.conf";
        quotes = "favorite_quotes.txt";
      };
      wallpapers =
        under profiles.main {
          downloaded = "Downloaded";
          fetched = "Fetched";
          preferred = "Favorites";
        }
        // {
          preferred = concat {
            root = paths.wallpapers.main;
            stem = "variety";
          };
        };
    };
    wallpapers.preferred = variety.wallpapers.preferred;
  in
    recursiveUpdate {inherit variety wallpapers;} paths;

  controller = let
    runtimeTools = [
      "coreutils"
      "ripgrep"
      "jaq"
      "procps"
      "findutils"
      "gnused"
      "gawk"
      "bash"
      "util-linux"
    ];
  in
    pkgs.writeShellScriptBin "varietyctl" ''
      PATH="${concatStringsSep ":" (map (name: toolkit.records.${name}.paths.binary) runtimeTools)}:$PATH"
      PATH="${pkgs.libnotify}/bin:$PATH"
      VARIETYCTL_BACKEND=${escapeShellArg wallpaper.cfg.backends.active}
      export PATH VARIETYCTL_BACKEND
      ${readFile paths'.variety.scripts.varietyctl}
    '';

  hooks = import ./outputs/hooks.nix {
    inherit cfg lix toolkit controller;
  };

  args = recursiveUpdate passthru {
    inherit cfg context controller hooks;
    paths = paths';
  };
in {
  options = import ./options args;
  outputs = import ./outputs args;
}
