{
  description = "Rust development environment with AI Tools";

  inputs = {
    NixPackages.url = "github:NixOS/nixpkgs/nixos-unstable";
    AI.url = "github:numtide/llm-agents.nix";
    Rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "NixPackages";
    };
    OpenClaw = {
      url = "github:Scout-DJ/openclaw-nix";
      inputs.nixpkgs.follows = "NixPackages";
    };
    Formatter = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "NixPackages";
    };
  };

  outputs = inputs @ {self, ...}: let
    cfg = import ./. {inherit inputs;};
    inherit (cfg) lib pkgs;
    inherit (lib.attrsets) mapAttrs;
    inherit (lib.shells) mkEnvironment;
    inherit (lib.packages) mkPkgsPerSystem;

    env = mkEnvironment {inherit inputs pkgs self;};
  in {
    inherit (cfg) lib pkgs paths project repl;
    inherit (env) checks devShells formatter;
    legacyPackages =
      mapAttrs
      (system: sysPkgs: sysPkgs // env.packages)
      (mkPkgsPerSystem {inherit inputs;});
  };
}
