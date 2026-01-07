{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.attrsets.resolution) byPaths;
  inherit (_.lists.predicates) isIn;
  inherit (_.modules.generators.environment) mkEnvironment mkLocale;
  inherit (_.modules.generators.style) mkFonts mkStyle;
  inherit (_.modules.generators.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.generators.home) mkUsers;
  inherit (_.modules.generators.software) mkNix mkBoot mkClean;
  inherit (_.modules.resolution) getSystem;
  inherit (lib.attrsets) filterAttrsRecursive mapAttrs mapAttrs';
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkMerge;
  inherit (lib.strings) hasInfix;

  mkInputs = {inputs}: {
    nixpkgs = byPaths {
      attrset = inputs;
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
      attrset = inputs;
      default = "nixpkgs-stable";
      paths = [
        ["nixPackagesStable"]
        ["nixosPackagesStable"]
        ["nixpkgs-stable"]
        ["nixpkgs"]
      ];
    };

    nixpkgs-unstable = byPaths {
      attrset = inputs;
      default = "nixpkgs-unstable";
      paths = [
        ["nixPackagesUnstable"]
        ["nixosPackagesUnstable"]
        ["nixpkgs-unstable"]
        ["nixpkgs"]
      ];
    };

    nix-darwin = byPaths {
      attrset = inputs;
      default = "nix-darwin";
      paths = [
        ["darwin"]
        ["nixDarwin"]
        ["darwinNix"]
      ];
    };

    chaotic = byPaths {
      attrset = inputs;
      default = "chaotic";
      paths = [
        ["nixChaotic"]
        ["kernelChaotic"]
        ["chaoticKernel"]
      ];
    };

    stylix = byPaths {
      attrset = inputs;
      default = "stylix";
      paths = [
        ["nixStyle"]
        ["styleManager"]
        ["darwinNix"]
      ];
    };

    home-manager = byPaths {
      attrset = inputs;
      default = "home-manager";
      paths = [
        ["nixHomeManager"]
        ["nixosHome"]
        ["nixHome"]
        ["homeManager"]
        ["home"]
      ];
    };

    fresh-editor = byPaths {
      attrset = inputs;
      default = "fresh-editor";
      paths = [
        ["fresh"]
        ["freshEditor"]
        ["editorFresh"]
      ];
    };

    helix = byPaths {
      attrset = inputs;
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
      attrset = inputs;
      default = "caelestia";
      paths = [
        ["shellCaelestia"]
        ["caelestia-shell"]
      ];
    };

    dank-material-shell = byPaths {
      attrset = inputs;
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
      attrset = inputs;
      default = "noctalia-shell";
      paths = [
        ["shellNoctalia"]
        ["noctalia-dev"]
        ["noctalia"]
      ];
    };

    quickshell = byPaths {
      attrset = inputs;
      default = "quickshell";
      paths = [
        ["shellQuick"]
        ["qtshell"]
        ["qmlshell"]
        ["quick"]
      ];
    };

    nvf = byPaths {
      attrset = inputs;
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
      attrset = inputs;
      default = "plasma";
      paths = [
        ["shellPlasma"]
        ["plasma-manager"]
        ["plasmaManager"]
        ["kde"]
      ];
    };

    treefmt = byPaths {
      attrset = inputs;
      default = "treefmt";
      paths = [
        ["treeFormatter"]
        ["fmtree"]
        ["treefmt-nix"]
      ];
    };

    typix = byPaths {
      attrset = inputs;
      default = "typix";
      paths = [
        ["docTypix"]
        ["typst"]
        ["typ"]
      ];
    };

    vscode-insiders = byPaths {
      attrset = inputs;
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
      attrset = inputs;
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

  mkPackages = {inputs}: {
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
    treefmt = inputs.treefmt.packages or {};
    typix = inputs.typix.packages or {};
    vscode-insiders = inputs.vscode-insiders.packages or {};
    zen-browser = inputs.zen-browser.packages or {};
  };

  mkOverlays = {
    inputs,
    packages,
    config,
  }: [
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

  mkModules = {
    inputs,
    host,
    packages,
    specialArgs,
    config,
    overlays,
  }: let
    class = host.class or "nixos";
    modulesPath = "${inputs.nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    nixpkgs =
      {
        hostPlatform = host.system;
        inherit config overlays;
      }
      // (
        with inputs.nixpkgs; (
          if (host.class or "nixos") == "darwin"
          then {source = outPath;}
          else {flake.source = outPath;}
        )
      );
    coreModules =
      (
        if class == "darwin"
        then [
          (inputs.home-manager.darwinModules.home-manager or {})
          (inputs.stylix.darwinModules.stylix or {})
        ]
        else [
          (inputs.home-manager.nixosModules.home-manager or {})
          (inputs.stylix.nixosModules.stylix or {})
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
      ]
      ++ [];

    homeModules = {
      dank-material-shell = {
        default = inputs.dank-material-shell.homeModules.default or {};
        niri = inputs.dank-material-shell.homeModules.niri or {};
      };
      noctalia-shell = inputs.noctalia-shell.homeModules or {};
      caelestia = inputs.caelestia.homeManagerModules or {};
      nvf = {default = inputs.nvf.homeManagerModules.default or {};};
      plasma = {default = inputs.plasma.homeModules.plasma-manager or {};};
      zen-browser = {
        twilight = inputs.zen-browser.homeModules.twilight or {};
        default = inputs.zen-browser.homeModules.default or {};
        beta = inputs.zen-browser.homeModules.beta or {};
      };
    };
    mkHomeModuleApps = {
      pkgs,
      user,
      config,
    }: {
      #| Plasma Desktop Environment
      plasma = {
        isAllowed =
          hasInfix "plasma" (user.interface.desktopEnvironment or "")
          || hasInfix "kde" (user.interface.desktopEnvironment or "");
        module = homeModules.plasma.default or {};
      };

      #| Caelestia Shell
      caelestia = {
        isAllowed = isIn ["caelestia-shell" "caelestia"] (
          (user.applications.allowed or [])
          ++ [(user.applications.bar or null)]
        );
        module = homeModules.caelestia.default or {};
      };

      #| Dank Material Shell
      dank-material-shell = {
        isAllowed = isIn ["dank-material-shell" "dank" "dms"] (
          (user.applications.allowed or [])
          ++ [(user.applications.bar or null)]
        );
        module = homeModules.dank-material-shell.default or {};
      };

      #| Noctalia Shell
      noctalia-shell = {
        isAllowed = isIn ["noctalia-shell" "noctalia" "noctalia-dev"] (
          (user.applications.allowed or [])
          ++ [(user.applications.bar or null)]
        );
        module = homeModules.noctalia-shell.default or {};
      };

      #| NVF (Neovim Framework)
      nvf = rec {
        isAllowed = isIn ["nvf" "nvim" "neovim"] (
          (user.applications.allowed or [])
          ++ [(user.applications.editor.tty.primary or null)]
          ++ [(user.applications.editor.tty.secondary or null)]
        );
        variant = "default";
        module = homeModules.nvf.${variant} or {};
      };

      #| Firefox - Zen Browser
      zen-browser = rec {
        isAllowed =
          hasInfix "zen" (user.applications.browser.firefox or "")
          || isIn ["zen" "zen-browser" "zen-twilight" "zen-browser"] (
            user.applications.allowed or []
          );
        variant =
          if hasInfix "twilight" (user.applications.browser.firefox or "")
          then "twilight"
          else "default";
        module = homeModules.zen-browser.${variant} or {};
      };
    };
    hostModules =
      [
        {inherit nixpkgs;}
        (
          {
            pkgs,
            config,
            ...
          }:
            mkMerge [
              (mkNix {inherit host;})
              (mkNetwork {inherit host pkgs;})
              (mkBoot {inherit host pkgs;})
              (mkFileSystems {inherit host;})
              (mkLocale {inherit host;})
              (mkAudio {inherit host;})
              (mkFonts {inherit host pkgs;})
              # (mkStyle {inherit host pkgs;}) # TODO: Not ready, build errors
              (mkUsers {
                inherit host pkgs specialArgs;
                extraSpecialArgs =
                  specialArgs
                  // {inherit src homeModules mkHomeModuleApps;};
              })
              (mkEnvironment {inherit config host pkgs packages;})
              (mkClean {inherit host;})
            ]
        )
      ]
      ++ (host.imports or []);
  in {
    inherit
      modulesPath
      baseModules
      coreModules
      homeModules
      hostModules
      nixpkgs
      ;
  };

  exports = {inherit mkInputs mkPackages mkOverlays mkModules;};
in
  exports // {_rootAliases = exports;}
