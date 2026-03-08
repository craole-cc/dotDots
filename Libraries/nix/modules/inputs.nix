{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.attrsets.resolution) byPaths;
  inherit (lib.lists) optionals;
  inherit (_.filesystem.paths) source;
  inherit (_.modules.resolution) getSystem;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';

  flake = _.attrsets.resolution.flake {inherit src;};
  rawInputs = flake.inputs;

  inputs = {
    nixpkgs = byPaths {
      attrsets = rawInputs;
      default = "nixpkgs";
      paths = [
        ["nixosCore"]
        ["nixPackages"]
        ["nixosPackages"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
      ];
    };

    nixpkgs-stable = byPaths {
      attrsets = rawInputs;
      default = "nixpkgs-stable";
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-unstable = byPaths {
      attrsets = rawInputs;
      default = "nixpkgs-unstable";
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixpkgs"]
      ];
    };

    nix-darwin = byPaths {
      attrsets = rawInputs;
      default = "nix-darwin";
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
      ];
    };

    home-manager = byPaths {
      attrsets = rawInputs;
      default = "home-manager";
      paths = [
        ["nixHomeManager"]
        ["nixosHome"]
        ["nixHome"]
        ["homeManager"]
        ["home"]
      ];
    };

    catppuccin = byPaths {
      attrsets = rawInputs;
      default = "catppuccin";
      paths = [
        ["styleCatppuccin"]
        ["catppuccinStyle"]
      ];
    };

    chaotic = byPaths {
      attrsets = rawInputs;
      default = "chaotic";
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
      ];
    };

    fresh-editor = byPaths {
      attrsets = rawInputs;
      default = "fresh-editor";
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
      ];
    };

    stylix = byPaths {
      attrsets = rawInputs;
      default = "stylix";
      paths = [
        ["nixStyle"]
        ["styleManager"]
        ["darwinNix"]
      ];
    };

    helix = byPaths {
      attrsets = rawInputs;
      default = "helix";
      paths = [
        ["helix-editor"]
        ["hx"]
        ["helixEditor"]
        ["editorHelix"]
        ["editorHX"]
      ];
    };
    caelestia = byPaths {
      attrsets = rawInputs;
      default = "caelestia";
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
      ];
    };
    dank-material-shell = byPaths {
      attrsets = rawInputs;
      default = "dank-material-shell";
      paths = [
        ["shellDankMaterial"]
        ["shellDank"]
        ["dank-material"]
        ["dank"]
        ["dms"]
      ];
    };
    noctalia-shell = byPaths {
      attrsets = rawInputs;
      default = "noctalia-shell";
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
      ];
    };

    quickshell = byPaths {
      attrsets = rawInputs;
      default = "quickshell";
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
      ];
    };

    nvf = byPaths {
      attrsets = rawInputs;
      default = "nvf";
      paths = [
        ["editorNeovim"]
        ["neovim"]
        ["nvim"]
        ["neovimFlake"]
        ["neoVim"]
      ];
    };

    plasma = byPaths {
      attrsets = rawInputs;
      default = "plasma";
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
      ];
    };

    treefmt = byPaths {
      attrsets = rawInputs;
      default = "treefmt";
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
      ];
    };

    typix = byPaths {
      attrsets = rawInputs;
      default = "typix";
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
      ];
    };

    vscode-insiders = byPaths {
      attrsets = rawInputs;
      default = "vscode-insiders";
      paths = [
        ["vscode"]
        ["code"]
        ["code-insiders"]
        ["vsc"]
        ["VSCode"]
        ["editorVscode"]
        ["editorVscodeInsiders"]
        ["vscode-insiders-nix"]
      ];
    };

    zen-browser = byPaths {
      attrsets = rawInputs;
      default = "zen-browser";
      paths = [
        ["browserZen"]
        ["firefoxZen"]
        ["zen"]
        ["zenBrowser"]
        ["zenFirefox"]
        ["twilight"]
      ];
    };
  };

  packages = {
    #~@ Core
    nixpkgs-stable = inputs.nixpkgs-stable.legacyPackages or {};
    nixpkgs-unstable = inputs.nixpkgs-unstable.legacyPackages or {};
    home-manager = inputs.home-manager.packages or {};

    #~@ Applications
    dank-material-shell = inputs.dank-material-shell.packages or {};
    fresh-editor = inputs.fresh-editor.packages or {};
    helix = inputs.helix.packages or {};
    noctalia-shell = inputs.noctalia-shell.packages or {};
    nvf = inputs.nvf.packages or {};
    plasma = inputs.plasma.packages or {};
    quickshell = inputs.quickshell.packages or {};
    caelestia = inputs.caelestia.packages or {};
    catppuccin = inputs.catppuccin.packages or {};
    treefmt = inputs.treefmt.packages or {};
    typix = inputs.typix.packages or {};
    vscode-insiders = inputs.vscode-insiders.packages or {};
    zen-browser = inputs.zen-browser.packages or {};
  };

  coreModules = {class ? "nixos", ...}:
    (
      if class == "darwin"
      then [
        (inputs.home-manager.darwinModules.home-manager or {})
        (inputs.stylix.darwinModules.stylix or {})
      ]
      else [
        (inputs.home-manager.nixosModules.home-manager or {})
        (inputs.stylix.nixosModules.stylix or {})
        (inputs.catppuccin.nixosModules.default or {})
        (inputs.chaotic.nixosModules.default or {})
      ]
    )
    ++ optionals (class == "darwin") [
      {
        system = {
          checks.verifyNixPath = false;
          darwinVersionSuffix = ".${
            inputs.nix-darwin.shortRev or
            inputs.nix-darwin.dirtyShortRev or
            "dirty"
          }";
          darwinRevision =
            inputs.nix-darwin.rev or inputs.nix-darwin.dirtyRev or "dirty";
        };
      }
    ];

  homeModules = {
    dank-material-shell = {
      default = inputs.dank-material-shell.homeModules.default or {};
      niri = inputs.dank-material-shell.homeModules.niri or {};
    };
    noctalia-shell = inputs.noctalia-shell.homeModules or {};
    caelestia = inputs.caelestia.homeManagerModules or {};
    catppuccin = inputs.catppuccin.homeModules or {};
    nvf = {default = inputs.nvf.homeManagerModules.default or {};};
    plasma = {default = inputs.plasma.homeModules.plasma-manager or {};};
    zen-browser = {
      twilight = inputs.zen-browser.homeModules.twilight or {};
      default = inputs.zen-browser.homeModules.default or {};
      beta = inputs.zen-browser.homeModules.beta or {};
    };
  };

  mkModule = {
    name,
    modules,
    variant ? "default",
  }:
    modules.${name}.${variant} or {};

  mkModules = {class ? "nixos", ...}: let
    path = "${inputs.nixpkgs}/nixos/modules";
    base = import "${path}/module-list.nix";
    core = coreModules {inherit class;};
    home = homeModules;
    all = {
      baseModules = base;
      coreModules = core;
      homeModules = home;
      modulesPath = path;
    };
  in
    {inherit all base core home path;} // all;

  mkPackages = {host}: let
    pkgs = host.packages;
    config = {
      allowUnfree = pkgs.allowUnfree or false;
      allowBroken = pkgs.allowBroken or false;
    };
    overlays = mkOverlays {inherit config;};
    nixpkgs =
      {
        hostPlatform = host.system;
        inherit config overlays;
      }
      // (source {inherit host inputs;});
  in {inherit nixpkgs inputs packages overlays;};

  mkOverlays = {config}: [
    #~@ Stable
    (final: prev: {
      fromStable = import inputs.nixpkgs-stable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Unstable
    (final: prev: {
      fromUnstable = import inputs.nixpkgs-unstable {
        inherit config;
        system = getSystem final;
      };
    })

    #~@ Flake inputs
    #? Flattened packages (higher priority)
    (final: prev:
      filterAttrsRecursive (name: value: value != null) (
        mapAttrs' (_name: pkgsSet: {
          name = _name;
          value = pkgsSet.${getSystem prev}.${"default"} or null;
        })
        packages
      ))

    #? Categorized (lower priority, for browsing)
    (final: prev: {
      fromInputs =
        mapAttrs (
          _: pkgs: pkgs.${getSystem prev} or {}
        )
        packages;
    })

    #~@ Chaotic overlay
    (inputs.chaotic.overlays.default or (_: _: {}))
  ];

  exports = {
    inherit
      inputs
      flake
      rawInputs
      packages
      coreModules
      homeModules
      mkModule
      mkModules
      mkPackages
      ;
    getCoreInputModules = coreModules;
    getHomeInputModules = homeModules;
    getInputs = inputs;
    mkInputPackages = mkPackages;
    mkInputModules = mkModules;
    mkInputModule = mkModule;
  };
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        getInputs
        getCoreInputModules
        getHomeInputModules
        mkInputPackages
        mkInputModules
        mkInputModule
        ;
    };
  }
