{
  description = "dotDots Flake Configuration";

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

    editorTypix = {
      repo = "typix";
      owner = "loqusion";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    editorVSCode = {
      repo = "vscode-insiders-nix";
      owner = "auguwu";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    editorVSCodeExtensions = {
      repo = "nix-vscode-extensions";
      owner = "nix-community";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

    secretsManager = {
      repo = "agenix";
      owner = "ryantm";
      type = "github";
      inputs.nixpkgs.follows = "nixPackages";
    };

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

    ai = {
      repo = "llm-agents.nix";
      owner = "numtide";
      type = "github";
    };

    hermes = {
      repo = "hermes-agent";
      owner = "NousResearch";
      type = "github";
    };
  };

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = inputs @ {...}: let
    lib = import ./. {
      inputs = inputs // {nixpkgs = inputs.nixPackages;};
      # flake = {
      #   inherit inputs;
      #   _type = "flake";
      #   name = "dots";
      #   path = self.outPath;
      # };
    };
  in
    {inherit lib;}
    // (
      with lib.libraries.default.modules.construction;
        (mkConfigurations lib)
        // (mkUtilities lib)
    )
    // {
      repl = let
        _ = lib.libraries.default;
        inherit (_.lib) filter isPath length match;
        inherit (_.sources) modules;
        inherit (_.modules.evaluation) evalModules;

        classifiedNixos = modules.mkModules {
          class = "nixos";
          inherit (lib) inputs;
        };

        # minimal stub so evalModules doesn't fail on unrelated missing system config
        stub = {nixpkgs.hostPlatform = "x86_64-linux";};

        t1 = evalModules {modules = [stub] ++ classifiedNixos.base;};
        t2 = evalModules {modules = [stub] ++ classifiedNixos.base ++ classifiedNixos.core;};
      in {
        inherit t1 t2;
        t1hostName = t1.config.networking.hostName;
        t2hostName = t2.config.networking.hostName;
        coreLength = length classifiedNixos.core;
        usesNixpkgsAlias = lib.inputs ? nixpkgs;
        basePath = classifiedNixos.path;
        baseHasNetworking =
          filter (
            path:
              isPath path
              && match ".*network-interfaces\\.nix" (toString path) != null
          )
          classifiedNixos.base;
      };
    };
}
