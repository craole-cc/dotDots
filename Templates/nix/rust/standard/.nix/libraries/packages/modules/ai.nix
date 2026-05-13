/**
packages/ai.nix

Resolve AI/LLM CLI tooling from a normalized variant attrset.
*/
{lib}: let
  inherit (lib.attrsets) optionalAttrs recursiveUpdate;
  inherit (lib.packages) mkBins mkPkg;
in {
  mkAI = {
    pkgs,
    variant ? {},
  }: let
    cfg =
      recursiveUpdate {
        kind = "workflow";
        name = "ai";
        enable = true;
        includeCodex = true;
        includeClaude = true;
        includeGemini = true;
        includeHermes = true;
        includeOpenClaw = true;
      }
      (optionalAttrs (variant ? ai) variant.ai);
  in
    {configuration = cfg;}
    // optionalAttrs cfg.enable (let
      llm = pkgs.llm-agents or {};
      packages = let
        common =
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

        custom =
          {}
          // optionalAttrs (binaries.common ? codex) {
            cx = mkPkg {
              inherit pkgs;
              name = "cx";
              command = binaries.common.codex;
            };
            cx-auto = mkPkg {
              inherit pkgs;
              name = "cx-auto";
              script = ''exec ${binaries.common.codex} --full-auto "$@"'';
            };
          }
          // optionalAttrs (binaries.common ? claude-code) {
            claude = mkPkg {
              inherit pkgs;
              name = "claude";
              command = binaries.common.claude-code;
            };
            cc-auto = mkPkg {
              inherit pkgs;
              name = "cc-auto";
              script = ''exec ${binaries.common.claude-code} --dangerously-skip-permissions "$@"'';
            };
          }
          // optionalAttrs (binaries.common ? gemini) {
            claude = mkPkg {
              inherit pkgs;
              name = "claude";
              command = binaries.common.claude-code;
            };
            cc-auto = mkPkg {
              inherit pkgs;
              name = "cc-auto";
              script = ''exec ${binaries.common.claude-code} --dangerously-skip-permissions "$@"'';
            };
          }
          // optionalAttrs (binaries.common ? openclaw) {
            claw = mkPkg {
              inherit pkgs;
              name = "claw";
              command = binaries.common.openclaw;
            };
          }
          // optionalAttrs (binaries.common ? hermes) {
            hma = mkPkg {
              inherit pkgs;
              name = "hma";
              command = binaries.common.hermes;
            };
          };
        all = common // custom;
      in {inherit all common custom;};

      binaries = let
        common = mkBins packages.common;
        custom = mkBins packages.custom;
        all = common // common;
      in {inherit all common custom;};

      variables =
        {}
        // optionalAttrs cfg.includeClaude
        {ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";}
        // optionalAttrs cfg.includeCodex
        {
          OPENAI_API_KEY = "$OPENAI_API_KEY";
          CODEX_UNSAFE_ALLOW_NO_SANDBOX = "0";
        }
        // optionalAttrs cfg.includeGemini {
          GEMINI_API_KEY = "$GEMINI_API_KEY";
        }
        // optionalAttrs cfg.includeOpenClaw {}
        // optionalAttrs cfg.includeHermes {};
    in {inherit variables packages binaries;});
}
