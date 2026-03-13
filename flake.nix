{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    src = ./.;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit (import src {inherit lib src self;}) lix hosts tree;
    inherit (lix.hardware.system) perFlake;
  in
    perFlake {inherit hosts legacyPackages;} (
      {
        system,
        pkgs,
      }: {
        inherit
          (import tree.pkg.global.store {
            inherit src lib lix tree pkgs system;
            inputs = lix.mkInputs {inherit self;};
          })
          devShells
          formatter
          checks
          ;
      }
    )
    // (
      {nixosConfigurations = lix.mkSystems {inherit self;};}
      // import tree.kit.default.store
    );

  inputs = {
    nixPackages.url = "nixpkgs/nixos-unstable";
    nixPackagesUnstable.url = "nixpkgs/nixos-unstable";
    nixPackagesStable.url = "nixpkgs/nixos-25.11";

    nixHomeManager = {
      repo = "home-manager";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    nixDarwin = {
      repo = "nix-darwin";
      owner = "LnL7";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    nixChaotic = {
      ref = "nyxpkgs-unstable";
      repo = "nyx";
      owner = "chaotic-cx";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    browserZen = {
      repo = "zen-browser-flake";
      owner = "0xc000022070";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixHomeManager";
      };
    };

    editorAffinity = {
      repo = "affinity-nix";
      owner = "mrshmllow";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorHelix = {
      repo = "helix";
      owner = "helix-editor";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    # editorFresh = {
    #   repo = "fresh";
    #   owner = "sinelaw";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
    #   };
    # };

    editorNeovim = {
      repo = "nvf";
      owner = "notashelf";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorTypix = {
      repo = "typix";
      owner = "loqusion";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    editorVscode = {
      repo = "vscode-insiders-nix";
      owner = "auguwu";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellDankMaterial = {
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellCaelestia = {
      repo = "shell";
      owner = "caelestia-dots";
      type = "github";
      inputs = {
        #> Follows stable to avoid broken app2unit 1.0.3 in nixpkgs-unstable.
        #> app2unit fixupPhase looks for 'A2U__TERMINAL_HANDLER=xdg-terminal-exec'
        #> which no longer exists in the binary post upstream source changes.
        #> Revisit when unstable's app2unit derivation is fixed.
        nixpkgs.follows = "nixPackagesStable";
      };
    };

    shellNoctalia = {
      repo = "noctalia-shell";
      owner = "noctalia-dev";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    shellPlasma = {
      repo = "plasma-manager";
      owner = "pjones";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
        home-manager.follows = "nixHomeManager";
      };
    };

    shellQuick = {
      repo = "quickshell";
      owner = "outfoxxed";
      type = "github";
      inputs = {
        nixpkgs.follows = "nixPackages";
      };
    };

    styleManager = {
      repo = "stylix";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    styleCatppuccin = {
      repo = "nix";
      owner = "catppuccin";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };
  };
}
