/**
packages/ai.nix

Resolve AI/LLM CLI tooling from a normalized variant attrset.
*/
{lib}: let
  inherit (lib.attrsets) attrValues filterAttrs optionalAttrs;
  inherit (lib.packages) mkBins mkCmds mkPkg;
in {
  mkAI = {
    pkgs,
    variant ? {
      ai = {
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
        includeHermes = true;
        includeOpenClaw = true;
      };
    },
  }: let
    cfg = variant.ai or {};
    llm = pkgs.llm-agents or {};
  in
    {
      kind = "ai";
      all = [];
      env = {};
    }
    // optionalAttrs cfg.enable (let
      packages =
        {}
        // (
          optionalAttrs
          cfg.includeCodex
          {codex = llm.codex or pkgs.codex or null;}
        )
        // (
          optionalAttrs
          cfg.includeClaude
          {claude = llm.claude-code or pkgs.claude-code-bin or pkgs.claude-code or  null;}
        )
        // (
          optionalAttrs
          cfg.includeGemini
          {gemini = llm.gemini-cli or pkgs.gemini-cli-bin or pkgs.gemini-cli or null;}
        )
        // (
          optionalAttrs
          cfg.includeOpenClaw
          {openclaw = llm.openclaw or pkgs.openclaw or null;}
        )
        // (
          optionalAttrs
          cfg.includeHermes
          {hermes = llm.hermes-agent or pkgs.hermes or null;}
        )
        // {};

      binaries = {
        packages = mkBins packages;
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts =
        {}
        // optionalAttrs (binaries.packages ? codex) {
          cx = mkPkg {
            inherit pkgs;
            name = "cx";
            command = binaries.packages.codex;
          };
          cx-auto = mkPkg {
            inherit pkgs;
            name = "cx-auto";
            script = ''exec ${binaries.packages.codex} --full-auto "$@"'';
          };
        }
        // optionalAttrs (binaries.packages ? claude-code) {
          claude = mkPkg {
            inherit pkgs;
            name = "claude";
            command = binaries.packages.claude-code;
          };
          cc-auto = mkPkg {
            inherit pkgs;
            name = "cc-auto";
            script = ''exec ${binaries.packages.claude-code} --dangerously-skip-permissions "$@"'';
          };
        }
        // optionalAttrs (binaries.packages ? gemini) {
          claude = mkPkg {
            inherit pkgs;
            name = "claude";
            command = binaries.packages.claude-code;
          };
          cc-auto = mkPkg {
            inherit pkgs;
            name = "cc-auto";
            script = ''exec ${binaries.packages.claude-code} --dangerously-skip-permissions "$@"'';
          };
        }
        // optionalAttrs (binaries.packages ? openclaw) {
          claw = mkPkg {
            inherit pkgs;
            name = "claw";
            command = binaries.packages.openclaw;
          };
        }
        // optionalAttrs (binaries.packages ? hermes) {
          hma = mkPkg {
            inherit pkgs;
            name = "hma";
            command = binaries.packages.hermes;
          };
        };

      all = attrValues packages ++ attrValues scripts;

      # binaries = {
      #   packages = mkBins packages;
      #   scripts = mkBins scripts;
      #   all = binaries.packages // binaries.scripts;
      # };

      # scripts = let
      #   bin = binaries.packages;
      # in
      #   (mkCmds bin (p: p))
      #   // optionalAttrs (bin ? codex) {
      #     cx = bin.codex; # derivation
      #     cx-auto = mkPkg {
      #       inherit pkgs;
      #       name = "cx-auto";
      #       script = "${bin.codex}/bin/codex --full-auto";
      #     };
      #   }
      #   // optionalAttrs (bin ? claude) {
      #     claude = bin.claude; # derivation
      #     cc-auto = mkPkg {
      #       inherit pkgs;
      #       name = "cc-auto";
      #       script = "${bin.claude}/bin/claude --dangerously-skip-permissions";
      #     };
      #   }
      #   // optionalAttrs (bin ? gemini) {
      #     gi = mkPkg {
      #       inherit pkgs;
      #       name = "gi";
      #       script = "${bin.openclaw}/bin/openclaw";
      #     };
      #   }
      #   // optionalAttrs (bin ? openclaw) {
      #     claw = mkPkg {
      #       inherit pkgs;
      #       name = "claw";
      #       script = "${bin.openclaw}/bin/openclaw";
      #     };
      #   }
      #   // optionalAttrs (bin ? hermes) {
      #     hma = bin.hermes; # derivation
      #   };

      # all = attrValues packages ++ attrValues scripts;

      env =
        {}
        // optionalAttrs (cfg.includeClaude) {
          ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";
        }
        // optionalAttrs (cfg.includeCodex) {
          OPENAI_API_KEY = "$OPENAI_API_KEY";
          CODEX_UNSAFE_ALLOW_NO_SANDBOX = "0";
        }
        // optionalAttrs (cfg.includeGemini) {
          GEMINI_API_KEY = "$GEMINI_API_KEY";
        }
        // optionalAttrs (cfg.includeOpenClaw) {}
        // optionalAttrs (cfg.includeHermes) {};
    in {inherit all env packages binaries scripts;});
}
