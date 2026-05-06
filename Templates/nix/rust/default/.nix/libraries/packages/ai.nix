/**
libraries/packages/llm.nix

LLM-agent package selectors and command helpers for lib.packages.
*/
{lib}: let
  inherit (lib.attrsets) attrValues filterAttrs;
  inherit (lib.packages) resolveBins mkCmds;
  inherit (lib.trivial) isNotEmpty;

  /**
  Build a normalized view of installed LLM agent tooling.

  Returns package lists, binary paths, shell command aliases, and the standard
  API-key environment contract expected by the AI shell.

  # Type
  ```nix
  mkAI :: {
    pkgs :: AttrSet;
    lib :: AttrSet;
  } -> {
    packages :: [derivation];
    bin :: AttrSet;
    cmd :: AttrSet;
    env :: AttrSet;
  }
  ```

  # Examples
  ```nix
  mkAI { inherit pkgs lib; }
  # => {
  #   packages = [ ... ];
  #   bin.codex = "/nix/store/.../bin/codex";
  #   cmd.cx = "/nix/store/.../bin/codex";
  #   env.OPENAI_API_KEY = "$OPENAI_API_KEY";
  # }
  ```

  # Returns
  A normalized tool description containing package derivations, binary paths,
  shell command aliases, and expected API-key environment variables.
  */
  mkAI = {pkgs}: let
    tools = pkgs.llm-agents or {};
    packages = attrValues tools;
    bin = resolveBins tools;

    cmd =
      (mkCmds bin (path: path))
      // {
        # Standard Aliases
        cc = bin.claude or null;
        cx = bin.codex or null;
        gm = bin.gemini or null;
        oc = bin.opencode or null;

        # Flagged Aliases
        cc-auto = mkCmds {exe = bin.claude or null;} (p: "${p} --dangerously-skip-permissions");
        cx-full = mkCmds {exe = bin.codex or null;} (p: "${p} --full-auto");
      };

    env = {
      ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";
      OPENAI_API_KEY = "$OPENAI_API_KEY";
      GEMINI_API_KEY = "$GEMINI_API_KEY";
      CODEX_UNSAFE_ALLOW_NO_SANDBOX = "0";
    };
  in {inherit packages bin cmd env;};
in {inherit mkAI;}
