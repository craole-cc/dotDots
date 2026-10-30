{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  api = import ../../API/nix/paths;
  profile = import ../../API/nix/users/craole;
  tree = stems:
    lix.filesystem.construction.mkTree {
      inherit stems;
      roots = api.roots // {home = "/home/fixture";};
    };
  core = tree api.stems;
  home = tree (lib.recursiveUpdate api.stems profile.paths.stems);
  changed = tree (lib.recursiveUpdate api.stems {
    home.pictures = ["Images"];
    home.projects = ["Work"];
  });
  withDefaults =
    lix
    // {
      modules =
        lix.modules
        // {
          construction =
            lix.modules.construction
            // {
              mkContext = _arguments: {};
              mkConfig = specification: specification.options.default.default;
            };
        };
    };
  userVariables = import ../../Modules/nix/home/environment/variables.nix {
    lix = withDefaults;
    config = {};
    user.paths = home;
  };
  resolver.commands = _arguments: {
    editor = null;
    visual = null;
    primary = null;
  };
  coreVariables = import ../../Modules/nix/core/environment/variables.nix {
    lix =
      withDefaults
      // {
        applications =
          lix.applications
          // {
            resolution = {
              editors = resolver;
              browsers = resolver;
              terminals = resolver;
              launchers = resolver;
              bars = resolver;
            };
          };
      };
    config = {};
    host.users.data.primary.packages = {};
    inputs = {};
    pkgs.stdenv.hostPlatform.system = "x86_64-linux";
    names.src = "dots";
    paths = core // {roots.repo = "/checkout";};
  };
in {
  sharedDirectoryExport = coreVariables.PICTURES == "/home/fixture/Pictures" && coreVariables.MUSIC == "/home/fixture/Music";
  wallpaperFromAPI = coreVariables.WALLPAPERS == core.home.wallpapers.local;
  userProjectExport = userVariables.PRJ_CC == "/home/fixture/Projects/craole-cc";
  userVariableNotGlobal = !(coreVariables ? PRJ_CC);
  userPathsRemainAbsolute = userVariables.PROJECTS == "/home/fixture/Projects";
  apiOverridePropagates = changed.variablesByRoot.home.PICTURES == "/home/fixture/Images" && changed.variablesByRoot.home.PROJECTS == "/home/fixture/Work";
  flatVariablesPreserved = home.variables.PRJ_CC == home.variablesByRoot.home.PRJ_CC;
}
