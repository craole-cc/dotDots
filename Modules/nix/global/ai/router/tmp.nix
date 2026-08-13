{
  description = ''
    AI Assisted Development:
      + OmniRoute (free multi-provider AI gateway with quota-aware fallback)
      + OpenCode
      + curated agents from llm-agents.nix.
  '';

  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
    inherit
      (lib.attrsets)
      attrNames
      attrValues
      genAttrs
      mapAttrs
      filterAttrs
      ;
    inherit (lib.meta) getExe;
    inherit (lib.strings) concatMapStringsSep hasPrefix;

    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    eachSystem = genAttrs systems (
      system: let
        /**
        Package Sources
        */
        pkgs = {
          nix = inputs.nixpkgs.legacyPackages.${system};
          llm = inputs.llm-agents.packages.${system} or {};
        };

        inherit
          (pkgs.nix)
          cacert
          curl
          gum
          lsof
          mkShell
          procps
          tmux
          writeShellApplication
          ;
        opencode = pkgs.llm.opencode or pkgs.nix.opencode;
        opencode-desktop = pkgs.llm.opencode-desktop or pkgs.nix.opencode-desktop;
        nodejs = pkgs.nix.nodejs_22;

        /**
        Shared configuration
        */
        omnirouteVersion = "3.8.49";
        npxCacheDir = "$HOME/.cache/omniroute-flake/npx";
        dataDir = "$HOME/.local/share/omniroute";

        /**
        Shared Shell Helpers
        */
        gums = ''
          fmt_accent()  { gum style --foreground 212 "$@"; }
          fmt_warn()    { gum style --foreground 214 "$@"; }
          fmt_success() { gum style --foreground 82 --bold "$@"; }
          fmt_err()     { gum style --foreground 196 "$@"; }
          fmt_muted()   { gum style --foreground 244 "$@"; }
          fmt_faint()   { printf "%s\n" "$(gum style --faint "$@")"; }
        '';

        /**
        Shared command menu, printed by every devShell's shellHook (see
        mkMenuBox below). Kept in one place so the command list can't
        drift out of sync between minimal/core/code/hermes/extras.
        */
        menu =
          concatMapStringsSep "\n"
          (item: "  $(fmt_accent '${item.cmd}')   ${item.desc}")
          [
            {
              cmd = "air-daemon";
              desc = "start air gateway detached in tmux (idempotent)";
            }
            {
              cmd = "air-status";
              desc = "check if air gateway is running";
            }
            {
              cmd = "air-stop";
              desc = "kill the air tmux session";
            }
            {
              cmd = "air-start";
              desc = "run air gateway in the foreground";
            }
          ];

        menuFooter = concatMapStringsSep "\n" (x: x) [
          ''$(fmt_faint 'w/OpenCode CLI   |> nix develop .#code')''
          ''$(fmt_faint 'w/OpenCode GUI   |> nix develop .#core)''
          ''$(fmt_faint 'Hermes Toolchain |> nix develop .#hermes')''
          ''$(fmt_faint 'Additional Tools |> nix develop .#extras')''
        ];

        /**
        Full boxed menu, parameterized by a shell's own title/subtitle
        line so each devShell can print the same command list under its
        own banner instead of a bespoke one-off gum box per shell.
        */
        mkMenuBox = title: subtitle: ''
          ${gums}
          gum style \
            --border normal \
            --margin "1" \
            --padding "1" \
            --border-foreground 212 \
            "$(fmt_accent --bold '${title}')" \
            "$(fmt_faint '${subtitle}')" \
            "" \
            "$(gum style --bold 'Commands available:')" \
            "${menu}" \
            "" \
            "${menuFooter}"
        '';

        /*
        Grouped, namespaced package sets. Namespacing does the job pascalCase
        compounding used to — `minimal.run` instead of `airRun`, `core.code`
        instead of `airCode` — since the group already carries the "air"
        context. `core` extends `minimal`, `hermes`/`extras` are separate
        opt-in families. None of this is forced on you: devShells.default only
        ever builds `minimal`.
          .#core.<n>     — air/OmniRoute + OpenCode CLI/Desktop
          .#minimal.<n>  — air/OmniRoute only (tiny: npx + tmux + gum + curl)
          .#hermes.<n>   — the Hermes family from llm-agents.nix
          .#extras.<n>   — every other llm-agents.nix package, individually
        */
        core = let
          gateway = writeShellApplication {
            name = "air";
            runtimeInputs = [nodejs cacert];
            text = ''
              NPM_CONFIG_CACHE="${npxCacheDir}/npm-cache"
              NPM_CONFIG_UPDATE_NOTIFIER=false
              NODE_EXTRA_CA_CERTS="${cacert}/etc/ssl/certs/ca-bundle.crt"
              export NPM_CONFIG_CACHE NPM_CONFIG_UPDATE_NOTIFIER NODE_EXTRA_CA_CERTS
              exec ${nodejs}/bin/npx --yes "omniroute@${omnirouteVersion}" "$@"
            '';
          };

          start = writeShellApplication {
            name = "air-start";
            runtimeInputs = [gateway gum];
            text = ''
              ${gums}
              export DATA_DIR="${dataDir}"
              mkdir -p "$DATA_DIR"
              PORT_NUM="''${PORT:-20128}"
              fmt_accent --bold "air gateway starting -> http://localhost:$PORT_NUM"
              fmt_faint "Dashboard/API on the same port unless PORT/DASHBOARD_PORT overridden."
              exec air "$@"
            '';
          };

          daemon = writeShellApplication {
            name = "air-daemon";
            runtimeInputs = [tmux start gum];
            text = ''
              ${gums}
              SESSION="air"
              if tmux has-session -t "$SESSION" 2>/dev/null; then
                fmt_warn "air daemon already running in tmux session '$SESSION'"
                fmt_faint "Attach with: tmux attach -t $SESSION"
                exit 0
              fi
              tmux new-session -d -s "$SESSION" "air-run"
              fmt_success "air daemon started in detached tmux session '$SESSION'"
              fmt_faint "Attach with: tmux attach -t $SESSION"
              fmt_faint "Stop with:   air-stop"
            '';
          };

          stop = writeShellApplication {
            name = "air-stop";
            runtimeInputs = [tmux gum];
            text = ''
              ${gums}
              SESSION="air"
              if tmux has-session -t "$SESSION" 2>/dev/null; then
                tmux kill-session -t "$SESSION"
                fmt_err "air daemon stopped"
              else
                fmt_muted "air daemon is not running in tmux"
              fi
            '';
          };

          status = writeShellApplication {
            name = "air-status";
            runtimeInputs = [tmux curl gum lsof procps];
            text = ''
              ${gums}
              SESSION="air"
              PORT_TO_CHECK="''${PORT:-20128}"
              if tmux has-session -t "$SESSION" 2>/dev/null; then
                printf "%s %s\n" "$(fmt_success "●")" "tmux session: running ('$SESSION')"
              else
                printf "%s %s\n" "$(fmt_err "○")" "tmux session: not running ('$SESSION')"
              fi
              if curl -fsS "http://localhost:''${PORT_TO_CHECK}/v1" -o /dev/null 2>/dev/null; then
                printf "%s %s\n" "$(fmt_success "●")" "http endpoint: up (http://localhost:''${PORT_TO_CHECK})"
                if ! tmux has-session -t "$SESSION" 2>/dev/null; then
                  fmt_warn "  (endpoint is up but not inside the '$SESSION' tmux session — likely an orphaned process)"
                  if command -v lsof >/dev/null 2>&1; then
                    lsof -i ":''${PORT_TO_CHECK}" -sTCP:LISTEN 2>/dev/null | tail -n +2 | while read -r _ pid _; do
                      fmt_faint "  PID $pid — kill it with: kill $pid"
                    done
                  fi
                fi
              else
                printf "%s %s\n" "$(fmt_err "○")" "http endpoint: not responding on port ''${PORT_TO_CHECK}"
              fi
            '';
          };

          code = writeShellApplication {
            name = "air-code";
            runtimeInputs = [opencode];
            text = ''exec opencode "$@"'';
          };

          desktop = writeShellApplication {
            name = "air-desktop";
            runtimeInputs = [opencode-desktop];
            text = ''exec opencode-desktop "$@"'';
          };
        in {
          inherit
            gateway
            start
            code
            desktop
            status
            stop
            daemon
            ;
          run = start;

          # Aliases for backwards compatibility
          opencode = code;
          opencode-desktop = desktop;
          omniroute = gateway;
        };
        minimal = removeAttrs core ["code" "desktop"];
        code = removeAttrs core ["desktop"];

        /**
        Every package llm-agents.nix ships whose name starts with "hermes"
        Example: hermes-agent, hermes-one, hermes-hud, etc.
        */
        hermes =
          removeAttrs
          (filterAttrs (name: _: hasPrefix "hermes" name) pkgs.llm)
          ["hermes-desktop"];

        /*
        Every other package llm-agents.nix ships (claude-code, codex,
        gemini-cli, qwen-code, and whatever else gets added upstream), each
        addressable individually. `opencode`/`opencode-desktop` are dropped
        since `core` already handles those with a nixpkgs fallback. New agents
        upstream show up automatically; nothing to maintain here.
        */
        extras = removeAttrs pkgs.llm [
          "opencode"
          "opencode-desktop"
        ];

        shells = {
          minimal = {
            packages = (attrValues minimal) ++ [tmux gum nodejs lsof procps];
            shellHook = ''
              ${mkMenuBox "ai-route dev shell" "minimal — air/OmniRoute only"}
              air-daemon || true
            '';
          };

          /**
          `nix develop .#core`
          Opt-in shell with OpenCode CLI/Desktop (air-code / air-desktop).
          Kept out of devShells.default because opencode-desktop is Electron-based and sizeable.
          */
          core = {
            packages = shells.minimal.packages ++ (attrValues core);
            shellHook = mkMenuBox "Core Development Shell" "Adds: air-code (CLI), air-desktop (GUI)";
          };

          /**
          `nix develop .#code`
          Opt-in shell with OpenCode CLI only (air-code).
          Kept out of devShells.default/core split so the Electron-based
          air-desktop isn't forced on anyone who just wants the CLI.
          */
          code = {
            packages = shells.minimal.packages ++ (attrValues code);
            shellHook = mkMenuBox "AIR Development Shell" "Adds: air-code (CLI)";
          };

          # `nix develop .#hermes` — opt-in shell with the entire Hermes family
          # (hermes-agent, hermes-one/desktop, hermes-hud, ...) available.
          # Never built unless this shell is explicitly requested.
          hermes = {
            packages = shells.core.packages ++ attrValues hermes;
            shellHook =
              mkMenuBox "Hermes Development Shell"
              "Tools: ${concatMapStringsSep ", " (name: name) (attrNames hermes)}";
          };

          extras = {
            packages = shells.minimal.packages ++ attrValues extras;
            shellHook =
              mkMenuBox "Extras Development Shell"
              "Tools: ${concatMapStringsSep ", " (name: name) (attrNames extras)}";
          };

          default = shells.minimal;
        };
      in {
        # `default` must be a derivation, not a group, for bare `nix build`/
        # `nix run` to work — that's `minimal.default` (i.e. `air`).
        packages = {
          inherit core extras hermes minimal;
          default = core.code;
        };

        apps = let
          mk = pkgSet:
            mapAttrs (_: pkg: {
              type = "app";
              program = getExe pkg;
            })
            pkgSet;
        in {
          default = mk core;
          minimal = mk minimal;
          core = mk core;
          tui = mk core.code;
          gui = mk core.desktop;
          hermes = mk hermes;
          extras = mk extras;
        };

        devShells = mapAttrs (_: shell: mkShell shell) shells;
      }
    );
  in
    genAttrs
    ["packages" "apps" "devShells"]
    (key: mapAttrs (_: sys: sys.${key}) eachSystem)
    // {inherit inputs;};
}
