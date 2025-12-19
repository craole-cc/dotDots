{
  pkgs,
  lib,
  api,
  system,
  all,
  ...
}: let
  inherit (lib) findFirst head attrValues;

  #> Get nixosConfigurations from the evaluated flake outputs
  nixosConfigurations = all.nixosConfigurations or {};

  #> Find a host that matches current system
  matchingHost =
    findFirst
    (host: host.config.nixpkgs.hostPlatform.system or null == system)
    null
    (attrValues nixosConfigurations);

  #> Get the current host
  currentHost =
    if matchingHost != null
    then matchingHost
    else head (attrValues nixosConfigurations);
  # currentConfig = nixosConfigurations.${currentHost.name};
  host = api.hosts.${currentHost.config.networking.hostName};
  inherit (host.paths) dots;
in
  pkgs.mkShell {
    name = "dotDots";
    packages =
      import ./pkg.nix {inherit pkgs;}
      ++ import ./fmt.nix {inherit pkgs;};

    shellHook = ''
      DOTS=${dots};
      initialize_bin() {
        BINIT_PATH="$DOTS/Bin/shellscript/base/binit"
        if [ -f "$BINIT_PATH" ]; then
          printf "direnv: Loading binit...\n" >&2
          BINIT_ACTION="--run"

          if [ -x "$BINIT_PATH" ]; then :; else
            chmod +x "$BINIT_PATH"
          fi

          . "$BINIT_PATH"
        else
          printf "direnv: binit not found at %s\n" "$BINIT_PATH" >&2
        fi
      }
      initialize_bin

      # Create directory for wrapper scripts
      SHELL_BIN="$PWD/.direnv/bin"
      mkdir -p "$SHELL_BIN"

      # Helper to list hosts - simple and reliable
      cat > "$SHELL_BIN/h-hosts" << 'EOF'
      #!/usr/bin/env bash
      export NIX_CONFIG="experimental-features = nix-command flakes"
      # Simple direct approach
      nix eval --impure --expr 'builtins.attrNames (builtins.getFlake (toString ./.)).nixosConfigurations' --json | ${pkgs.jq}/bin/jq -r '.[]'
      EOF

      # Helper to show host info
      cat > "$SHELL_BIN/h-info" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      export NIX_CONFIG="experimental-features = nix-command flakes"
      nix eval --impure --expr '
        let
          flake = builtins.getFlake (toString ./.);
          hostConfig = flake.nixosConfigurations."'"$host"'";
        in {
          hostname = hostConfig.config.networking.hostName;
          system = hostConfig.config.nixpkgs.hostPlatform.system;
          kernel = hostConfig.config.boot.kernelPackages.kernel.version;
          stateVersion = hostConfig.config.system.stateVersion;
        }
      ' --json | ${pkgs.jq}/bin/jq .
      EOF

      # Helper to rebuild a host
      cat > "$SHELL_BIN/h-rebuild" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild switch --flake .#%s\n" "$host"
      EOF

      # Helper to test a host
      cat > "$SHELL_BIN/h-test" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild test --flake .#%s\n" "$host"
      EOF

      # Helper for boot
      cat > "$SHELL_BIN/h-boot" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild boot --flake .#%s\n" "$host"
      EOF

      # Helper for dry build
      cat > "$SHELL_BIN/h-dry" << 'EOF'
      #!/usr/bin/env bash
      host="''\${1:-${currentHost.config.networking.hostName}}"
      printf "sudo nixos-rebuild dry-build --flake .#%s\n" "$host"
      EOF

      # Helper for update
      cat > "$SHELL_BIN/h-update" << 'EOF'
      #!/usr/bin/env bash
      printf "nix flake update\n"
      EOF

      # Helper for cleanup
      cat > "$SHELL_BIN/h-clean" << 'EOF'
      #!/usr/bin/env bash
      printf "sudo nix-collect-garbage -d\n"
      EOF

      # Helper for listing all helpers
      cat > "$SHELL_BIN/h-list" << 'EOF'
      #!/usr/bin/env bash
      printf "\033[1;36m#~@ Available helpers\033[0m\n"
      printf "  \033[1;32mh-hosts\033[0m             - List all hosts\n"
      printf "  \033[1;32mh-info [host]\033[0m       - Show host info\n"
      printf "  \033[1;32mh-rebuild [host]\033[0m    - Rebuild command\n"
      printf "  \033[1;32mh-test [host]\033[0m       - Test command\n"
      printf "  \033[1;32mh-boot [host]\033[0m       - Boot command\n"
      printf "  \033[1;32mh-dry [host]\033[0m        - Dry build command\n"
      printf "  \033[1;32mh-update\033[0m            - Update flake\n"
      printf "  \033[1;32mh-clean\033[0m             - Clean garbage\n"
      printf "  \033[1;32mnixos-repl\033[0m          - Start Nix REPL with original repl.nix\n"
      printf "  \033[1;32mrepl\033[0m                - Start nix-repl\n"
      printf "\n"
      printf "\033[1;36m#~@ Quick usage\033[0m\n"
      printf "  Most helpers accept an optional host argument. Default: \033[1;33m${currentHost.config.networking.hostName}\033[0m\n"
      EOF

      # Helper for REPL help
      cat > "$SHELL_BIN/repl-help" << 'EOF'
      #!/usr/bin/env bash
      printf "\033[1;36m#> NixOS Configuration REPL\033[0m\n"
      printf "\033[1;36m#> Current context:\033[0m\n"
      printf "  Host: \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
      printf "  System: \033[1;32m${system}\033[0m\n"
      printf "\n"
      printf "\033[1;36m#> Available commands:\033[0m\n"
      printf "  h-list             - Show all helpers\n"
      printf "  h-hosts            - List all configured hosts\n"
      printf "  h-info [host]      - Show host information\n"
      printf "  nixos-repl         - Start REPL with original repl.nix\n"
      printf "  repl               - Start nix-repl\n"
      EOF

      # Make scripts executable
      chmod +x "$SHELL_BIN"/*
      export PATH="$SHELL_BIN:$PATH"

      # Show welcome message
      printf "\033[1;36m🎯 NixOS Configuration REPL\033[0m\n"
      printf "\033[1;30m============================\033[0m\n\n"
      printf "\033[1;33mCurrent host:\033[0m \033[1;32m${currentHost.config.networking.hostName}\033[0m\n"
      printf "\033[1;33mSystem:\033[0m \033[1;32m${system}\033[0m\n\n"
      printf "Type \033[1;32mh-list\033[0m for available helpers\n"
      printf "Type \033[1;32mnixos-repl\033[0m to start Nix REPL with your configuration\n"
      printf "Type \033[1;32mrepl\033[0m to start nix-repl\n\n"
    '';
  }
