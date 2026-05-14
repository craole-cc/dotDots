{
  description = "Rust development environment with AI Tools";

  inputs = {
    NixPackages.url = "github:NixOS/nixpkgs/nixos-unstable";

    AI = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "NixPackages";
    };

    Rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "NixPackages";
    };

    # OpenClaw = {
    #   url = "github:Scout-DJ/openclaw-nix";
    #   inputs.nixpkgs.follows = "NixPackages";
    # };

    Formatter = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "NixPackages";
    };
  };

  outputs = inputs @ {self, ...}: let
    cfg = import ./. {inherit inputs;};
    inherit (cfg) lib;
    inherit (lib.modules) mkConfig;
  in
    mkConfig {
      inherit inputs self;
      configuration = let
        common.enable = true;
        extra = {
          enable = true;
          includeMise = true;
          includeFetch = true;
          includeGitTools = true;
          includeFileTools = true;
          includeRustScript = true;
        };
        ai = {
          enable = true;
          includeCodex = true;
          includeClaude = true;
          includeGemini = true;
          includeHermes = true;
          includeOpenClaw = true;
        };
        rust = {
          enable = true;
          channel = "nightly";
          minimal = true;
          includeDocs = true;
          includeFmt = true;
          includeAnalyzer = true;
          includeWeb = true;
          includeLeptos = true;
          includeExtra = true;
          extraTargets = [];
          extraExtensions = [];
        };
        web = {
          enable = true;
          includeDeno = true;
          includePnpm = true;
          includeTrunk = true;
        };
        db = {
          enable = true;
          includeMysql = true;
          includePostgres = true;
          includeMariaDB = true;
          includeSqlite = true;
        };
        ide = {
          enable = false;
          editors = [];
        };
        fmt = {
          enable = true;
          includeAlejandra = true;
          includeNixfmt = true;
          includeShfmt = true;
          includeShellcheck = true;
          includeStatix = true;
          includeDeno = true;
          includePrettier = true;
          includeRustfmt = true;
          includeLeptosfmt = true;
          includeSqlfmt = true;
          includeSqruff = true;
          includeXmllint = true;
        };
      in {inherit ai common db extra fmt ide rust web;};
    };
}
