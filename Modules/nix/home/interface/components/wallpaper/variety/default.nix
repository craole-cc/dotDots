/*
Variety wallpaper manager, declaratively (home-manager module).

Layout
  default.nix  resolves shared context, packages and Variety paths
  options/     declares typed options, setting defaults and wallpaper sources
  outputs/     renders variety.conf, wraps the package and installs the profile

The parent wallpaper component imports this module and controls enablement.
*/
{
  config,
  inputs,
  lix,
  paths,
  pkgs,
  wallpaper,
  ...
} @ args: let
  context = mkContext {
    inherit config;
    dom = "interface";
    sub = "wallpaper";
    mod = "variety";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.strings.predicates) hasPrefix;
  inherit (lix.filesystem.construction) concat;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.sources.packages) pkgsFrom;
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
      scripts =
        under (concat {
          root = paths.store.lib.sh;
          stem = "interface/wallpaper";
        }) {
          varietyctl = "varietyctl";
        };
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

  tool = let
    runtimeTools = [
      "coreutils"
      "ripgrep"
      "jaq"
      "jq"
      "procps"
      "findutils"
      "gnused"
      "gawk"
      "bash"
      "util-linux"
    ];

    controller = pkgs.writeShellScriptBin "varietyctl" ''
      PATH="${concatStringsSep ":" (map (name: defined.records.${name}.paths.binary) runtimeTools)}:$PATH"
      VARIETYCTL_BACKEND=${escapeShellArg wallpaper.cfg.backend}
      export PATH VARIETYCTL_BACKEND
      ${readFile paths'.variety.scripts.varietyctl}
    '';

    defined = pkgsFrom {
      inherit inputs;
      pkgs = pkgs // {varietyctl = controller;};
      sources = genAttrs (["variety" "varietyctl" "sd"] ++ runtimeTools) (_name: null);
      required = true;
    };

    custom = let
      packages = [defined.records.varietyctl.package];
      binaries = genAttrs ["install" "tr" "rm"] (name:
        concat {
          root = defined.records.coreutils.paths.binary;
          stem = name;
        });

      hooks = import ./outputs/hooks.nix {
        inherit cfg pkgs lix;
        tool = defined;
      };
    in {inherit packages binaries hooks;};
  in
    recursiveUpdate defined custom;

  args' =
    args
    // {
      inherit cfg context tool;
      paths = paths';
    };
in
  mkConfig {
    inherit context;
    options = import ./options args';
    outputs = import ./outputs args';
  }
