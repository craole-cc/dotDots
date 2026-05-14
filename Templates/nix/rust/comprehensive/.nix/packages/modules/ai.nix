{lib}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs;
  inherit (lib.packages) mkBins mkPkg;
in {
  mkAI = {
    pkgs,
    variant ? {},
  }: let
    name = "ai";
    cfg = let
      set1 = {
        inherit name;
        kind = "workflow";
        enable = false;
        includeCodex = false;
        includeClaude = false;
        includeGemini = false;
        includeHermes = false;
        includeOpenClaw = false;
      };
      set2 = variant.ai or {};
      set3 = recursiveAttrs {inherit set1 set2;};
      set4 = {};
    in {
      inherit
        set1
        set2
        set3
        set4
        ;
      final = recursiveAttrs {inherit set3 set4;};
    };
    configuration = cfg.final;
  in
    {
      inherit configuration;
    }
    // optionalAttrs configuration.enable (
      with configuration; let
        llm = pkgs.llm-agents or {};

        packages = let
          common =
            {}
            // optionalAttrs includeCodex {codex = llm.codex or pkgs.codex or null;}
            // optionalAttrs includeClaude {claude-code = llm.claude-code or pkgs.claude-code-bin or pkgs.claude-code or null;}
            // optionalAttrs includeGemini {gemini-cli = llm.gemini-cli or pkgs.gemini-cli-bin or pkgs.gemini-cli or null;}
            // optionalAttrs includeOpenClaw {openclaw = llm.openclaw or pkgs.openclaw or null;}
            // optionalAttrs includeHermes {hermes = llm.hermes-agent or pkgs.hermes or null;};

          custom = with binaries.common;
            {}
            // optionalAttrs (binaries.common ? codex) {
              cx = mkPkg {
                inherit pkgs;
                name = "cx";
                command = codex;
              };
              cx-auto = mkPkg {
                inherit pkgs;
                name = "cx-auto";
                script = ''exec ${codex} --full-auto "$@"'';
              };
            }
            // optionalAttrs (binaries.common ? claude-code) {
              cc = mkPkg {
                inherit pkgs;
                name = "cc";
                command = claude-code;
              };
            }
            // optionalAttrs (binaries.common ? gemini-cli) {
              gi = mkPkg {
                inherit pkgs;
                name = "gi";
                command = gemini-cli;
              };
            }
            // optionalAttrs (binaries.common ? openclaw) {
              claw = mkPkg {
                inherit pkgs;
                name = "claw";
                command = openclaw;
              };
            }
            // optionalAttrs (binaries.common ? hermes) {
              hma = mkPkg {
                inherit pkgs;
                name = "hma";
                command = hermes;
              };
            };

          all = common // custom;
        in {
          inherit all common custom;
        };

        binaries = let
          common = mkBins packages.common;
          custom = mkBins packages.custom;
          all = common // custom;
        in {
          inherit all common custom;
        };

        variables =
          {}
          // optionalAttrs includeClaude {ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";}
          // optionalAttrs includeCodex {
            OPENAI_API_KEY = "$OPENAI_API_KEY";
            CODEX_UNSAFE_ALLOW_NO_SANDBOX = "0";
          }
          // optionalAttrs includeGemini {GEMINI_API_KEY = "$GEMINI_API_KEY";}
          // optionalAttrs includeOpenClaw {}
          // optionalAttrs includeHermes {};

        messages = null;
      in {
        inherit
          variables
          packages
          binaries
          messages
          ;
      }
    );
}
