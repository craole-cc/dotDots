{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.devshell.flakeModule];

  devshells.default = {
    name = "openclaw-dev";

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

    packages = with pkgs; [
      # Formatters / linters
      treefmt
      nixfmt
      nodePackages.prettier
      shfmt
      taplo
      deadnix
      statix

      # Secret management
      sops
      age

      # Nix tooling
      nix-tree
      nix-diff
    ];
  };
}
