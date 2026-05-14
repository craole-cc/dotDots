{
  description = "Research & document writing dev shell — Typst + AI agents";

  #╔═══════════════════════════════════════════════════════════╗
  #║ Binary cache                                              ║
  #╚═══════════════════════════════════════════════════════════╝

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
    ];

    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Inputs                                                    ║
  #╚═══════════════════════════════════════════════════════════╝

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Outputs                                                   ║
  #╚═══════════════════════════════════════════════════════════╝

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    llm-agents,
    treefmt-nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = pkgs.lib;
      inherit (lib.attrsets) hasAttr;
      inherit (lib.lists) optionals;
      inherit (lib.strings) concatStringsSep;

      llm = llm-agents.packages.${system};
      llmPkg = name:
        if hasAttr name llm
        then llm.${name}
        else
          throw ''
            llm-agents.nix does not expose package `${name}` for system `${system}`.

            Try:
              nix flake show github:numtide/llm-agents.nix
              nix flake show .#devShells.${system}
          '';

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";

        programs = {
          alejandra.enable = true;
          deno.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
          typstyle.enable = true;
          typos.enable = true;
        };
      };

      #╔═══════════════════════════════════════════════════════╗
      #║ Shared paths                                          ║
      #╚═══════════════════════════════════════════════════════╝

      fontPaths = concatStringsSep ":" (
        map (pkg: "${pkg}/share/fonts") [
          pkgs.liberation_ttf
          pkgs.noto-fonts
        ]
      );

      #╔═══════════════════════════════════════════════════════╗
      #║ Package groups                                        ║
      #╚═══════════════════════════════════════════════════════╝

      toolchain = {
        markup = with pkgs; [
          typst
          tinymist
        ];

        bibliography = with pkgs; [
          biber
          pandoc
          zotero
        ];

        prose = with pkgs; [
          aspell
          aspellDicts.en
          aspellDicts.en-science
          hunspell
          ltex-ls
          vale
        ];

        media = with pkgs; [
          ghostscript
          gnuplot
          imagemagick
          inkscape
          mermaid-cli
          poppler-utils
          python3Packages.matplotlib
        ];

        vcs = with pkgs; [
          delta
          git
          git-lfs
        ];

        shell = with pkgs;
          [
            bat
            fd
            fzf
            gum
            jq
            mise
            ripgrep-all
            tree
            watchexec
          ]
          ++ optionals stdenv.isLinux [wl-clipboard];

        secrets = with pkgs; [
          age
          sops
        ];

        ai-agents = [
          (llmPkg "codex")
          (llmPkg "gemini-cli")
          pkgs.ollama
        ];

        ai-assistants = [
          (llmPkg "openclaw")
          (llmPkg "hermes-agent")
        ];

        ai-ops = [
          (llmPkg "ccusage-codex")
          (llmPkg "skills")
          (llmPkg "skills-installer")
        ];
      };

      #╔═══════════════════════════════════════════════════════╗
      #║ Shell helpers                                         ║
      #╚═══════════════════════════════════════════════════════╝

      loadSecrets = file: ''
        export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/age/keys.txt}"

        if [[ -f "${file}" ]]; then
          if sops --decrypt --output-type dotenv "${file}" >/dev/null 2>&1; then
            set -a
            source <(sops --decrypt --output-type dotenv "${file}")
            set +a
          else
            gum style --foreground 1 "⚠  Could not decrypt ${file}. Check SOPS_AGE_KEY_FILE=$SOPS_AGE_KEY_FILE"
          fi
        else
          gum style --foreground 3 "⚠  No secrets file found at ${file}"
        fi
      '';

      showAiKeyStatus = ''
        _configured=()
        _missing_optional=()

        [[ -n "''${GEMINI_API_KEY:-}" || -n "''${GOOGLE_API_KEY:-}" ]] \
          && _configured+=("Gemini API key")

        [[ -n "''${OPENAI_API_KEY:-}" ]] \
          && _configured+=("OpenAI API key")

        [[ -n "''${OPENROUTER_API_KEY:-}" ]] \
          && _configured+=("OpenRouter API key")

        [[ -n "''${ANTHROPIC_API_KEY:-}" ]] \
          && _configured+=("Anthropic API key")

        [[ -n "''${COPILOT_GITHUB_TOKEN:-}" || -n "''${GH_TOKEN:-}" || -n "''${GITHUB_TOKEN:-}" ]] \
          && _configured+=("GitHub/Copilot token")

        if command -v ollama >/dev/null 2>&1; then
          if ollama list >/dev/null 2>&1; then
            _configured+=("Ollama running locally")
          else
            _missing_optional+=("Ollama installed, but server is not running")
          fi
        fi

        if [[ ''${#_configured[@]} -gt 0 ]]; then
          gum style --foreground 2 "✓ AI provider(s) detected:"
          for item in "''${_configured[@]}"; do
            printf '  %s %s\n' "$(gum style --foreground 2 '•')" "$item"
          done
        else
          gum style \
            --border normal \
            --border-foreground 3 \
            --padding "0 2" \
            "$(gum style --foreground 3 --bold 'No cloud API key detected')"

          printf '  %s %s\n' "$(gum style --foreground 3 '•')" "Set GEMINI_API_KEY or GOOGLE_API_KEY for Gemini"
          printf '  %s %s\n' "$(gum style --foreground 3 '•')" "Or use Hermes OAuth setup with: hermes model"
          printf '  %s %s\n' "$(gum style --foreground 3 '•')" "Or use local Ollama with: ollama serve"
        fi

        if [[ ''${#_missing_optional[@]} -gt 0 ]]; then
          gum style --foreground 3 "Optional:"
          for item in "''${_missing_optional[@]}"; do
            printf '  %s %s\n' "$(gum style --foreground 3 '•')" "$item"
          done
        fi
      '';

      assistantShellHelpers = ''
          export OLLAMA_CONTEXT_LENGTH="''${OLLAMA_CONTEXT_LENGTH:-8192}"
          export OLLAMA_HOST="''${OLLAMA_HOST:-127.0.0.1:11434}"

          alias ollama-serve-cpu='OLLAMA_CONTEXT_LENGTH=8192 ollama serve'
          alias ollama-serve-hermes='OLLAMA_CONTEXT_LENGTH=65536 ollama serve'
          alias ollama-models='ollama list'

          alias hermes-setup='hermes setup'
          alias hermes-model='hermes model'
          alias hermes-check='hermes config check'
          alias hermes-chat='hermes chat'

          alias ai-local='hermes model'
          alias ai-chat='hermes chat'

          cat <<'EOF'

        Assistant helper commands:
          hermes setup          # first-time Hermes setup
          hermes model          # choose/switch Gemini, Anthropic, OpenAI, Ollama, etc.
          hermes chat           # start Hermes
          ollama-serve-cpu      # start Ollama with CPU-friendly context length
          ollama pull qwen2.5-coder:3b
          ollama pull qwen2.5-coder:7b
          ollama pull llama3.2:3b
          ollama pull phi3:mini

        Recommended CPU-first local Ollama endpoint for Hermes:
          http://localhost:11434/v1

        Recommended model roles:
          Gemini / Anthropic / OpenAI  # main assistant models
          qwen2.5-coder:3b             # local coding fallback
          llama3.2:3b                  # local writing fallback

        EOF
      '';

      banner = {
        writing = ''
          gum style \
            --border normal \
            --border-foreground 4 \
            --padding "0 2" \
            "$(gum style --foreground 4 --bold 'Writing Shell')"
        '';

        agents = ''
          gum style \
            --border normal \
            --border-foreground 5 \
            --padding "0 2" \
            "$(printf '%s\n' \
              "$(gum style --foreground 5 --bold 'Agents Shell')" \
              "$(gum style --foreground 8 'codex · gemini-cli · ollama · skills')" \
            )"
        '';

        assistants = ''
          gum style \
            --border normal \
            --border-foreground 13 \
            --padding "0 2" \
            "$(printf '%s\n' \
              "$(gum style --foreground 13 --bold 'Assistants Shell')" \
              "$(gum style --foreground 8 'openclaw · hermes-agent')" \
            )"
        '';

        draft = ''
          gum style \
            --border normal \
            --border-foreground 6 \
            --padding "0 2" \
            "$(printf '%s\n' \
              "$(gum style --foreground 6 --bold 'Draft Shell')" \
              "$(gum style --foreground 8 'typst · aspell · codex · gemini-cli')" \
            )"
        '';

        full = ''
          gum style \
            --border double \
            --border-foreground 12 \
            --padding "1 3" \
            --margin "1 0" \
            "$(gum style --foreground 12 --bold 'Research & Document Writing Shell')"

          gum style \
            --border normal \
            --border-foreground 8 \
            --padding "0 2" \
            "$(printf '%s\n' \
              "$(gum style --foreground 4 'Typst      ') typst compile · typst watch" \
              "$(gum style --foreground 4 'LSP        ') tinymist" \
              "$(gum style --foreground 4 'Format     ') typstyle · treefmt" \
              "$(gum style --foreground 4 'Proofing   ') vale · typos · aspell · hunspell" \
              "$(gum style --foreground 4 'Agents     ') codex · gemini-cli · ollama" \
              "$(gum style --foreground 4 'Assistants ') openclaw · hermes-agent" \
              "$(gum style --foreground 4 'Secrets    ') sops · age" \
              "$(gum style --foreground 4 'Reload     ') watchexec -e typ -- typst compile main.typ" \
            )"
        '';
      };

      mkSecretShell = {
        name,
        packages,
        shellBanner,
        env ? {TYPST_FONT_PATHS = fontPaths;},
        extraShellHook ? "",
      }:
        pkgs.mkShell {
          inherit name env packages;

          shellHook = ''
            ${loadSecrets "secrets/api-keys.yaml"}
            ${shellBanner}
            ${showAiKeyStatus}
            ${extraShellHook}
          '';
        };

      mkPlainShell = {
        name,
        packages,
        shellHook ? "",
        env ? {TYPST_FONT_PATHS = fontPaths;},
      }:
        pkgs.mkShell {inherit name packages shellHook env;};
    in {
      #╔═══════════════════════════════════════════════════════╗
      #║ Code Quality                                          ║
      #╚═══════════════════════════════════════════════════════╝
      formatter = treefmtEval.config.build.wrapper;
      checks.formatting = treefmtEval.config.build.check self;

      #╔═══════════════════════════════════════════════════════╗
      #║ Development Shells                                    ║
      #╚═══════════════════════════════════════════════════════╝

      devShells = let
        inherit
          (toolchain)
          ai-agents
          ai-assistants
          ai-ops
          bibliography
          markup
          media
          prose
          secrets
          shell
          vcs
          ;
        #? Headless shell for CI/checks.
        ci = mkPlainShell {
          name = "ci";

          packages =
            bibliography
            ++ markup
            ++ media
            ++ prose;
        };

        #? Prose-focused shell. No AI, no secrets.
        writing = mkPlainShell {
          name = "writing";

          packages =
            bibliography
            ++ markup
            ++ media
            ++ prose
            ++ shell
            ++ vcs;

          shellHook = banner.writing;
        };

        #? Agents only.
        agents = mkSecretShell {
          name = "agents";

          packages =
            ai-agents
            ++ ai-ops
            ++ secrets
            ++ shell;

          shellBanner = banner.agents;
        };

        #? Assistants only.
        assistants = mkSecretShell {
          name = "assistants";

          packages =
            ai-assistants
            ++ ai-agents
            ++ secrets
            ++ shell;

          shellBanner = banner.assistants;
          extraShellHook = assistantShellHelpers;
        };

        #? AI-assisted writing shell.
        draft = mkSecretShell {
          name = "draft";

          packages =
            ai-agents
            ++ markup
            ++ prose
            ++ secrets
            ++ shell;

          shellBanner = banner.draft;
        };

        #? Full research + writing + agents + assistants environment.
        full = mkSecretShell {
          name = "research-writing";

          packages =
            ai-agents
            ++ ai-assistants
            ++ ai-ops
            ++ bibliography
            ++ markup
            ++ media
            ++ prose
            ++ secrets
            ++ shell
            ++ vcs;

          shellBanner = banner.full;
          extraShellHook = assistantShellHelpers;
        };
      in {
        default = draft;
        minimal = ci;
        inherit ci writing agents assistants draft full;
      };
    });
}
