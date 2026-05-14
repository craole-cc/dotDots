{
  description = "Rust development environment with AI Tools";

  inputs = {
    NixPackages.url = "github:NixOS/nixpkgs/nixos-unstable";

    # AI = {
    #   url = "github:numtide/llm-agents.nix";
    #   inputs.nixpkgs.follows = "NixPackages";
    # };

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
        common.enable = false;
        extra = {
          enable = false;
          includeMise = false;
          includeFetch = false;
          includeGitTools = false;
          includeFileTools = false;
          includeRustScript = false;
        };
        ai = {
          enable = false;
          includeCodex = false;
          includeClaude = false;
          includeGemini = false;
          includeHermes = false;
          includeOpenClaw = false;
        };
        rust = {
          enable = false;
          channel = "nightly";
          minimal = false;
          includeDocs = false;
          includeFmt = false;
          includeAnalyzer = false;
          includeWeb = false;
          includeLeptos = false;
          includeExtra = false;
          extraTargets = [];
          extraExtensions = [];
        };
        web = {
          enable = false;
          includeDeno = false;
          includePrettier = false;
          includeTrunk = false;
        };
        db = {
          enable = false;
          includeMysql = false;
          includePostgres = false;
          includeRedis = false;
          includeSqlite = false;
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
