/**
packages/ai.nix

Resolve AI/LLM CLI tooling from a normalized variant attrset.
*/
{lib}: let
  inherit
    (lib.attrsets)
    attrValues
    filterAttrs
    mapAttrs
    optionalAttrs
    ;
  inherit (lib.packages) mkBins mkCmds;
in {
  mkAI = {
    pkgs,
    variant ? {
      ai = {
        enable = false;
        includeCodex = false;
        includeClaude = false;
        includeHermes = false;
        includeOpenClaw = false;
      };
    },
  }: let
    cfg = variant.ai or {};

    registry = {
      codex = {
        enable = cfg.includeCodex or false;
        package = pkgs.codex or null;
      };
      claude = {
        enable = cfg.includeClaude or false;
        package = pkgs.claude-code or null;
      };
      hermes = {
        enable = cfg.includeHermes or false;
        package = pkgs.hermes or null;
      };
      opencode = {
        enable = cfg.includeOpenClaw or false;
        package = pkgs.openclaw or null;
      };
    };

    selected =
      mapAttrs (_: v: v.package)
      (filterAttrs (_: v: v.enable && v.package != null) registry);

    bin = mkBins selected;

    cmd =
      (mkCmds bin (p: p))
      // optionalAttrs (bin ? claude) {
        cc = bin.claude;
        cc-auto = "${bin.claude} --dangerously-skip-permissions";
      }
      // optionalAttrs (bin ? codex) {
        cx = bin.codex;
        cx-full = "${bin.codex} --full-auto";
      }
      // optionalAttrs (bin ? opencode) {
        oc = bin.opencode;
      }
      // optionalAttrs (bin ? hermes) {
        hm = bin.hermes;
      };

    env = optionalAttrs (cfg.enable or false) {
      ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";
      OPENAI_API_KEY = "$OPENAI_API_KEY";
      GEMINI_API_KEY = "$GEMINI_API_KEY";
      CODEX_UNSAFE_ALLOW_NO_SANDBOX = "0";
    };

    all = attrValues selected;
  in {
    kind = "ai";
    inherit cfg registry selected all bin cmd env;
    packages = selected;
  };
}
