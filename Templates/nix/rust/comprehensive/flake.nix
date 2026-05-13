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
    removeAttrs (mkConfig {inherit inputs self;}) [
      "modules"
    ];
}
