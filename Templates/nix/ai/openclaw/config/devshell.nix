{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  pre-commit-check = import ./checks/pre-commit.nix {inherit inputs pkgs;};
  packages = with pkgs; [
    # treefmt
    # nixfmt
    # prettier
    # shfmt
    # taplo
    # deadnix
    # statix
    # sops
    # age
    # nix-tree
    # nix-diff
    # gh

    # Formatters / linters
    # treefmt
    # nixfmt
    # nodePackages.prettier
    # shfmt
    # taplo
    # deadnix
    # statix

    # Secret management
    sops
    age

    # Nix tooling
    nix-tree
    nix-diff

    gh
  ];

  env = [
    {
      name = "OPENCLAW_LOG_LEVEL";
      value = "info";
    }
    {
      name = "OPENCLAW_PORT";
      value = "8080";
    }
    {
      name = "SOPS_AGE_KEY_FILE";
      #? Operators override this in .envrc.local.
      value = "$HOME/.config/sops/age/keys.txt";
    }
    #? GITHUB_TOKEN must be set in .envrc.local — no default provided here.
  ];

  commands = [
    {
      name = "fmt";
      help = "Format all source files via treefmt";
      command = "treefmt";
      category = "dev";
    }
    {
      name = "check";
      help = "Run nix flake check";
      command = "nix flake check";
      category = "dev";
    }
    {
      name = "build";
      help = "Build the openclaw package";
      command = "nix build .#openclaw";
      category = "dev";
    }
    {
      name = "run";
      help = "Run openclaw directly";
      command = "nix run .#openclaw";
      category = "dev";
    }
    {
      name = "test";
      help = "Build and run the NixOS VM unit test";
      command = "nix build .#checks.x86_64-linux.openclaw-unit";
      category = "dev";
    }
    {
      name = "secrets-edit";
      help = "Edit encrypted secrets with sops";
      command = "sops secrets/secrets.yaml";
      category = "secrets";
    }
    {
      name = "gh";
      help = "GitHub CLI";
      package = pkgs.gh;
      category = "github";
    }
    {
      name = "ghpr";
      help = "Create a GitHub pull request (auto-fill from branch)";
      command = "gh pr create --fill";
      category = "github";
    }
    {
      name = "ghci";
      help = "Create a GitHub issue";
      command = "gh issue create";
      category = "github";
    }
    {
      name = "update";
      help = "Update all flake inputs";
      command = "nix flake update";
      category = "dev";
    }
  ];

  shellHook = ''
    ${pre-commit-check.shellHook}

    export OPENCLAW_LOG_LEVEL="''${OPENCLAW_LOG_LEVEL:-info}"
    export OPENCLAW_PORT="''${OPENCLAW_PORT:-8080}"
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

    alias fmt='treefmt'
    alias check='nix flake check'
    alias build='nix build .#openclaw'
    alias run='nix run .#openclaw'
    alias test='nix build .#checks.${system}.openclaw-unit'
    alias secrets-edit='sops secrets/secrets.yaml'
    alias ghpr='gh pr create --fill'
    alias ghci='gh issue create'
    alias update='nix flake update'
  '';
in
  pkgs.mkShell {inherit packages env commands shellHook;}
