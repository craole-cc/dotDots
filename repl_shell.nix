{
  pkgs,
  api,
  lix,
  lib,
  system,
  all,
}: let
  # Import your REPL module
  repl = import ./repl.nix {
    inherit api lix lib pkgs system;
    inherit all;
  };
in
  pkgs.mkShell {
    name = "nixos-config-repl";

    packages = with pkgs; [
      nix
      nix-repl
      jq
      yq-go
      nix-tree
      nix-diff
      nix-prefetch
    ];

    shellHook = ''
      echo "🎯 NixOS Configuration REPL Shell"
      echo "================================="
      echo ""
      echo "Current host: ${repl.config.networking.hostName}"
      echo "System: ${system}"
      echo ""
      echo "Quick access:"
      echo "  • Type 'h' for helpers"
      echo "  • Type 'config.' and press Tab for completion"
      echo "  • Type 'lib.' for Nixpkgs lib functions"
      echo ""
      echo "Useful commands:"
      echo "  rebuild-host    - Rebuild current host"
      echo "  list-hosts      - List all configured hosts"
      echo "  host-info <name> - Show host details"
      echo ""

      # Create helper functions
      list-hosts() {
        nix eval --expr '(import ./repl.nix).helpers.listHosts' --json | jq -r '.[]'
      }

      host-info() {
        local host=''${1:-${repl.config.networking.hostName}}
        nix eval --expr "(import ./repl.nix).helpers.hostInfo \"$host\"" --json | jq .
      }

      rebuild-host() {
        local host=''${1:-${repl.config.networking.hostName}}
        echo "sudo nixos-rebuild switch --flake .#$host"
      }

      # Create a simple REPL launcher
      cat > .direnv/bin/nixos-repl << 'EOF'
      #!/usr/bin/env bash
      exec nix repl ./repl.nix "$@"
      EOF
      chmod +x .direnv/bin/nixos-repl

      export PATH="$PWD/.direnv/bin:$PATH"
    '';

    # Export the REPL module
    inherit (repl) config helpers pkgs lib;

    # Short alias
    h = repl.helpers;
  }
