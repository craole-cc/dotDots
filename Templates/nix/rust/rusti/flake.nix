{
  description = "AI + Rust Development Environment";

  inputs = {
    NixPackages.url = "github:NixOS/nixpkgs/nixos-unstable";
    Rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "NixPackages";
    };
    # OpenClaw = {
    #   url = "github:Scout-DJ/openclaw-nix";
    #   inputs.nixpkgs.follows = "NixPackages";
    # };

    #? nixpkgs.follows intentionally omitted — see modules/packages/llm.nix
    AI.url = "github:numtide/llm-agents.nix";
  };

  outputs = inputs @ {...}: import ./. {inherit inputs;};
}
