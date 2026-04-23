{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    treefmt
    nixfmt
    prettier
    shfmt
    taplo
    deadnix
    statix
    sops
    age
    nix-tree
    nix-diff
    gh
  ];

  shellHook = ''
    export OPENCLAW_LOG_LEVEL="''${OPENCLAW_LOG_LEVEL:-info}"
    export OPENCLAW_PORT="''${OPENCLAW_PORT:-8080}"
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

    alias fmt='treefmt'
    alias check='nix flake check'
    alias build='nix build .#openclaw'
    alias run='nix run .#openclaw'
    alias test='nix build .#checks.${pkgs.stdenv.hostPlatform.system}.openclaw-unit'
    alias secrets-edit='sops secrets/secrets.yaml'
    alias ghpr='gh pr create --fill'
    alias ghci='gh issue create'
    alias update='nix flake update'
  '';
}
