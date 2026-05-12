/**
packages/ai.nix

Resolve AI/LLM CLI tooling from a normalized variant attrset.
*/
{lib}: let
  inherit (lib.attrsets) attrValues filterAttrs optionalAttrs;
  inherit (lib.packages) mkBins mkCmds;
in {
  mkAI = {
    pkgs,
    variant ? {},
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
      packages = filterAttrs (_: v: v != null) {
        codex =
          if cfg.includeCodex
          then (llm.codex or pkgs.codex or null)
          else null;
        claude =
          if cfg.includeClaude
          then (llm.claude-code or pkgs.claude-code or pkgs.claude-code-bin or null)
          else null;
        gemini =
          if cfg.includeGemini
          then (llm.gemini-cli or pkgs.gemini-cli-bin or pkgs.gemini-cli or null)
          else null;
        hermes =
          if cfg.includeHermes
          then (llm.hermes-agent or null)
          else null;
        openclaw =
          if cfg.includeOpenClaw
          then (llm.openclaw or pkgs.openclaw or null)
          else null;
      };

      binaries = {
        packages = mkBins packages;
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts =
        (mkCmds binaries (p: p))
        // optionalAttrs (binaries ? codex) {
          cx = binaries.codex;
          cx-auto = "${binaries.codex} --full-auto";
        }
        // optionalAttrs (binaries ? claude) {
          inherit (binaries) claude;
          cc-auto = "${binaries.claude} --dangerously-skip-permissions";
        }
        // optionalAttrs (binaries ? gemini) {
          gi = binaries.openclaw;
        }
        // optionalAttrs (binaries ? openclaw) {
          claw = binaries.openclaw;
        }
        // optionalAttrs (binaries ? hermes) {
          hma = binaries.hermes;
        };

      all = attrValues packages ++ attrValues scripts;

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
