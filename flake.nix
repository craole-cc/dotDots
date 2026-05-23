{
  description = "dotDots Flake Configuration";

  outputs = inputs @ {self, ...}: let
    flake = self;
    inherit (inputs.nixPackages) lib legacyPackages;
    inherit (import ./. {inherit flake lib;}) lix tree schema top paths;
    inherit (lix.modules.construction) mkFlake mkSystems;
    inherit (lix.sources.inputs) normalize;

    args = {
      inputs = normalize {inherit flake;};
      inherit flake lix top;
    };

    resolved = mkFlake {
      inherit legacyPackages;
      fn = {
        system,
        pkgs,
      }:
        import tree.store.mod.global {
          inherit lix pkgs system paths;
          inherit (lix) lib;
          inherit (args) inputs;
        };
    };
  in {
    inherit args;
    inherit (resolved) devShells formatter checks;
    nixosConfigurations = mkSystems {
      inherit schema tree;
      inherit (args) inputs;
      extraArgs = args;
    };

    templates = import tree.store.kit.nix;
  };

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
      inputs.nixpkgs.follows = "nixPackages";
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

    # editorAffinity = {
    #   repo = "affinity-nix";
    #   owner = "mrshmllow";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    editorHelix = {
      repo = "helix";
      owner = "helix-editor";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    # editorFresh = {
    #   repo = "fresh";
    #   owner = "sinelaw";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # editorNeovim = {
    #   repo = "nvf";
    #   owner = "notashelf";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # editorTypix = {
    #   repo = "typix";
    #   owner = "loqusion";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # editorVSCode = {
    #   repo = "vscode-insiders-nix";
    #   owner = "auguwu";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # editorVSCodeExtensions = {
    #   repo = "nix-vscode-extensions";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # secretsManager = {
    #   repo = "agenix";
    #   owner = "ryantm";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    shellDankMaterial = {
      # ref = "stable";
      repo = "DankMaterialShell";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };
    shellDankMaterialPlugins = {
      repo = "dms-plugin-registry";
      owner = "AvengeMedia";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    # shellCaelestia = {
    #   repo = "shell";
    #   owner = "caelestia-dots";
    #   type = "github";
    #   inputs = {
    #     #> Follows stable to avoid broken app2unit 1.0.3 in nixpkgs-unstable.
    #     #> app2unit fixupPhase looks for 'A2U__TERMINAL_HANDLER=xdg-terminal-exec'
    #     #> which no longer exists in the binary post upstream source changes.
    #     #> Revisit when unstable's app2unit derivation is fixed.
    #     nixpkgs.follows = "nixPackagesStable";
    #   };
    # };

    # shellNoctalia = {
    #   repo = "noctalia-shell";
    #   owner = "noctalia-dev";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # shellPlasma = {
    #   repo = "plasma-manager";
    #   owner = "pjones";
    #   type = "github";
    #   inputs = {
    #     nixpkgs.follows = "nixPackages";
    #     home-manager.follows = "nixHomeManager";
    #   };
    # };

    # shellQuick = {
    #   repo = "quickshell";
    #   owner = "outfoxxed";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # styleManager = {
    #   repo = "stylix";
    #   owner = "nix-community";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    # styleCatppuccin = {
    #   repo = "nix";
    #   owner = "catppuccin";
    #   type = "github";
    #   inputs.nixpkgs.follows = "nixPackages";
    # };

    treeFormatter = {
      repo = "treefmt-nix";
      owner = "numtide";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    ai = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
      # inputs.nixpkgs.follows = "nixPackages";
    };
  };
}
