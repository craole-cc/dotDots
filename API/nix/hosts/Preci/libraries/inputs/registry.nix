{
  sources = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
      sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
    };

    rust-overlay = {
      type = "github";
      owner = "oxalica";
      repo = "rust-overlay";
      rev = "f60c1b57ff805a46b5175c76fc981fb4f81efbcc";
      sha256 = "sha256-r4LDUF+zmJnkftvCVkCrUhSJazsf6EVJF+V2l4/MYbI=";
    };

    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "4900baf1e219645e4a2acba35723852b2091bc20";
      sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
    };

    dotDots = {
      type = "github";
      owner = "craole-cc";
      repo = "dotDots";
      rev = "main";
    };

    nix-index = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index-database";
      rev = "9ad722673ab3b3f91f02135e53775825b240b869";
      sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
    };

    catppuccin = {
      type = "github";
      owner = "catppuccin";
      repo = "nix";
      rev = "89b3eacf59d6b5eefbc2d69c3a4eb5aaf66d63bc";
      sha256 = "sha256-W5dvgFOuVs24X3G5tUb8C2IHU7ICXNvyGPiWWFjfbuo=";
    };

    catppuccin-konsole = {
      type = "pin";
      owner = "catppuccin";
      repo = "konsole";
      rev = "3b64040e3f4ae5afb2347e7be8a38bc3cd8c73a8";
      hash = "sha256-d5+ygDrNl2qBxZ5Cn4U7d836+ZHz77m6/yxTIANd9BU=";
    };

    sops-nix = {
      type = "github";
      owner = "Mic92";
      repo = "sops-nix";
      rev = "5efb5a6f4f5ab192817d28557dd4d650fa14d866";
      sha256 = "sha256-rs9meAYxW3zzrh43yaW7htrqCD+X9+pupDPHN86fumI=";
      flake = true;
    };

    hermes-agent = {
      type = "github";
      owner = "NousResearch";
      repo = "hermes-agent";
      rev = "e3dd27ee2d8b011737a4eea8e3eb3d711ab78690";
      sha256 = "sha256-y6NaoG+HCeMPhxRsBXrRFef4hp3FF1svSPNKpI6Xz/E=";
      flake = true;
    };

    llm-agents = {
      type = "github";
      owner = "numtide";
      repo = "llm-agents.nix";
      rev = "3a78485c5ec8c10ec53915410c724a4492cea4bb";
      sha256 = "sha256-Ho5xXKbluCp1lmvUkVwrN76fUW1NC3RARdNaFMGpEcY=";
      flake = true;
    };

    buuf-nestort = {
      type = "pin";
      url = "https://git.disroot.org/eudaimon/buuf-nestort";
      rev = "ba218523983aec90f1e9facaefeeeeecdcf6d6a5";
      hash = "sha256-6aEM+rL7chkP83Rol6/F5jmG3mo6vALPk2pIvkUK1rU=";
    };
  };

  modules = {
    core = {
      catppuccin = {
        source = "catppuccin";
        path = "modules/nixos";
      };
      hermes-agent = {
        source = "hermes-agent";
        class = "nixos";
      };
      home-manager = {
        source = "home-manager";
        path = "nixos";
      };
      nix-index = {
        source = "nix-index";
        path = "nixos-module.nix";
      };
      sops = {
        source = "sops-nix";
        outputs = ["nixosModules" "sops"];
      };
    };
    home = {
      hermes-agent = {
        source = "hermes-agent";
        class = "homeManager";
      };
      sops = {
        source = "sops-nix";
        class = "homeManager";
      };
    };
  };

  overlays = [
    "rust-overlay"
  ];
}
