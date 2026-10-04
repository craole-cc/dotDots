{
  sources = {
    #~@ Core
    dotDots = {
      type = "github";
      owner = "craole-cc";
      repo = "dotDots";
      rev = "main";
    };

    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "20b1ddd1aa5ace70c9468305030aa4f9ef79671b";
      sha256 = "sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0=";
    };

    home-manager = {
      type = "github";
      owner = "nix-community";
      repo = "home-manager";
      rev = "4900baf1e219645e4a2acba35723852b2091bc20";
      sha256 = "sha256-BOyZoliWfm/beS4m3FxFKlu5at6npZen1PsWtvzzihk=";
    };

    #~@ Others
    buuf-nestort = {
      type = "pin";
      url = "https://git.disroot.org/eudaimon/buuf-nestort";
      rev = "ba218523983aec90f1e9facaefeeeeecdcf6d6a5";
      hash = "sha256-6aEM+rL7chkP83Rol6/F5jmG3mo6vALPk2pIvkUK1rU=";
    };

    cachyos-kernel = {
      type = "github";
      owner = "xddxdd";
      repo = "nix-cachyos-kernel";
      rev = "12b3164acdc3eb61afc7420e9d406964e925510f";
      sha256 = "sha256-N6C5Ptcce45xz8czhDUePiI7KyfGf5f/oECWhEbDtGk=";
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

    nix-index = {
      type = "github";
      owner = "nix-community";
      repo = "nix-index-database";
      rev = "9ad722673ab3b3f91f02135e53775825b240b869";
      sha256 = "sha256-Dkg4VKPmDPqTwaiw2WH5br73tXoL1qrOO0xJnR4TlcA=";
    };

    rust-overlay = {
      type = "github";
      owner = "oxalica";
      repo = "rust-overlay";
      rev = "f60c1b57ff805a46b5175c76fc981fb4f81efbcc";
      sha256 = "sha256-r4LDUF+zmJnkftvCVkCrUhSJazsf6EVJF+V2l4/MYbI=";
    };

    sops-nix = {
      type = "github";
      owner = "Mic92";
      repo = "sops-nix";
      rev = "5efb5a6f4f5ab192817d28557dd4d650fa14d866";
      sha256 = "sha256-rs9meAYxW3zzrh43yaW7htrqCD+X9+pupDPHN86fumI=";
      flake = true;
    };

    zen-browser = {
      type = "github";
      owner = "0xc000022070";
      repo = "zen-browser-flake";
      rev = "e56900732d1fa6f360db502451a457ffe3ca1e6e";
      sha256 = "sha256-jr7YVkvOYS+bJjzBwoqtN8b8inJN8UDWziWufAWH1SY=";
    };
  };
  #? `always` separates the two kinds of module.
  #?
  #? `always = true`  the module is part of every host's configuration and
  #?                   declares options this repository depends on --
  #?                   `sops` supplies `config.sops`, without which
  #?                   `modules/core/secrets.nix` has nothing to read.
  #?
  #? `always` absent   the module exists but is inert until something asks
  #?                   for it. `services.hermes-agent` is behind
  #?                   `mkIf cfg.enable`, so importing it on a host that
  #?                   wants no agent costs an unused option subtree and
  #?                   nothing more.
  #?
  #? The distinction has to live here rather than being inferred, because
  #? `context/modules.nix` cannot tell "needed on every host" from "waiting
  #? for a request" by looking at a resolved module -- both arrive as an
  #? attrset with imports. Without it, a request for `hermes` is
  #? indistinguishable from sops being wired up for the twenty-first time.
  modules = {
    core = {
      #? `always`, because `modules/core/environment/default.nix` sets
      #? `catppuccin.flavor`/`accent` unconditionally. Without the module that
      #? is an undefined option, not a degraded theme.
      catppuccin = {
        source = "catppuccin";
        path = "modules/nixos";
        always = true;
      };
      hermes-agent = {
        source = "hermes-agent";
        class = "nixos";
      };
      #? `always`, because `modules/home/users.nix` sets `home-manager.users`,
      #? `useGlobalPkgs` and friends unconditionally. Without the module that is
      #? an undefined option, not a missing convenience.
      home-manager = {
        source = "home-manager";
        path = "nixos";
        always = true;
      };
      #? `always`, because `modules/core/programs/default.nix` sets
      #? `nix-index.enable` and `nix-index-database` unconditionally. The
      #? alternative is to gate those settings on
      #? `context.modules.enabled.core."nix-index"`, which is truer to the gate
      #? but means a host without the module silently loses a faster `nix
      #? shell` -- so it is a real decision, not a mechanical fix.
      nix-index = {
        source = "nix-index";
        path = "nixos-module.nix";
        always = true;
      };
      sops = {
        source = "sops-nix";
        outputs = ["nixosModules" "sops"];
        always = true;
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
        always = true;
      };
    };
  };

  #? Only sources whose root import is itself an overlay -- a function of
  #? `(final, prev)`. `mkNixPkgs` passes this list straight to nixpkgs, so
  #? anything else here is either silently ignored or throws.
  #?
  #? `rust-overlay` qualifies: `import path` is `final: prev: {...}` and adds
  #? the `rust-bin` channel set.
  overlays = [
    "rust-overlay"
  ];

  #? Sources that are *not* overlays, and the shape each one actually has.
  #? A package name in `specs` names an entry here, and `context/` turns that
  #? into a derivation: this is where "the spec stays dumb" is paid for.
  #?
  #? `zen-browser`: `import path` is a function of `{pkgs, ...}` returning an
  #? attrset of *derivations* -- `twilight`, `beta`, `default`, each already
  #? built against the pkgs it was handed. So a user asking for
  #? `zen-twilight` is resolved by selecting a key from this attrset, not by
  #? applying an overlay and looking up a name.
  #?
  #? `cachyos-kernel`: `import path` is a flake-compat shim that fetches
  #? flake-compat and reads `flake.lock`, so it is neither an overlay nor a
  #? package set. `loadPackages.nix` in the same tree takes `(inputs, pkgs)`
  #? and returns all 96 `linux-cachyos-*` / `linuxPackages-cachyos-*` names.
  packageSets = [
    "zen-browser"
  ];

  #? Entry points that are neither overlays nor package-set functions, given
  #? as `path` within the fetched tree plus the positional arguments it takes.
  #? cachyOS is applied to a *pinned* package set (`inputs.nixpkgs`), not to
  #? the one `mkNixPkgs` builds, because a kernel overlay has to agree with
  #? the nixpkgs it was built against.
  packageLoaders = {
    "cachyos-kernel" = {
      file = "loadPackages.nix";
      args = ["inputs" "pkgs"];
    };
  };

  #? Sources with no `default.nix` at all, whose outputs are only reachable
  #? through `flake.packages.<system>`. `hermes-agent` is one: importing its path
  #? fails outright, so a package-set entry could never read it.
  #?
  #? Listed separately from `packageSets` because the mechanism differs -- no
  #? function is called, the flake is read -- and because only a flake has
  #? per-system outputs to select.
  packageFlakes = ["hermes-agent"];
}
