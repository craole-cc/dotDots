{lib}: let
  /**
  Build the Rust-focused shell specification.

  # Type
  ```nix
  mkRustSpec :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkRustSpec {
    inherit lib pkgs mkTools mkEnvironment mkTemplates mkWelcome;
    channel = "stable";
  }
  # => {
  #   __meta.kind = "rust";
  #   shell.name = "rust-stable";
  #   ...
  # }
  ```

  # Returns
  A shell spec containing Rust packages, environment variables, and shell initialization.
  */
  mkRustSpec = {
    pkgs,
    mkTools,
    mkEnvironment,
    mkTemplates,
    mkWelcome,
    channel ? "nightly",
  }: let
    inherit (lib.packages) mkRust;
    inherit (pkgs.stdenv) isDarwin;
    inherit (pkgs.lib.lists) optionals;

    rust = mkRust {inherit pkgs channel;};
    templates = mkTemplates {inherit pkgs;};
    tools = mkTools {inherit pkgs rust templates;};
    env = mkEnvironment {inherit rust channel;};
    welcome = mkWelcome {inherit pkgs tools;};
  in {
    __meta = {
      kind = "rust";
      inherit channel rust templates tools welcome pkgs;
    };

    shell = {
      name = "rust-${channel}";
      packages = tools.packages ++ optionals isDarwin [pkgs.libiconv];
      inherit env;
      shellHook = ''
        ${tools.init}
        [ -n "$PRJ_HOME" ] || PRJ_HOME=$PWD
        [ -n "$PRJ_NAME" ] || PRJ_NAME=$(basename "$PRJ_HOME")
        RUST_VERSION=$(${tools.rustvv})
        export PRJ_HOME PRJ_NAME RUST_VERSION
        ${welcome}
      '';
    };
  };

  /**
  Build the AI-tooling shell specification.

  # Type
  ```nix
  mkAiSpec :: {
    lib :: AttrSet;
    pkgs :: AttrSet;
  } -> AttrSet
  ```

  # Examples
  ```nix
  mkAiSpec { inherit lib pkgs; }
  # => {
  #   __meta.kind = "ai";
  #   shell.name = "ai-dev";
  #   ...
  # }
  ```

  # Returns
  A shell spec for the AI toolchain and its expected environment variables.
  */
  mkAiSpec = {
    lib,
    pkgs,
  }: let
    inherit (lib.packages) mkOpenClaw mkLLM;

    claw = mkOpenClaw {inherit pkgs;};
    llm = mkLLM {inherit pkgs lib;};
  in {
    __meta = {
      kind = "ai";
      inherit claw llm pkgs;
    };

    shell = {
      name = "ai-dev";
      packages = [claw.package] ++ llm.packages;
      inherit (llm) env;
      shellHook = ''
        echo "🤖 AI Development Environment"
        echo "   Tools: openclaw, claude-code, codex, gemini-cli, opencode"
        echo "   Set ANTHROPIC_API_KEY / OPENAI_API_KEY / GEMINI_API_KEY as needed."
      '';
    };
  };

  /**
  Merge the Rust and AI shell specifications into a combined shell.

  # Type
  ```nix
  mkCombinedSpec :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkCombinedSpec {
    inherit lib pkgs mkTools mkEnvironment mkTemplates mkWelcome;
    channel = "nightly";
  }
  # => {
  #   __meta.kind = "combined";
  #   shell.name = "full-nightly";
  #   ...
  # }
  ```

  # Returns
  A merged shell spec combining the Rust and AI environments.
  */
  mkCombinedSpec = {
    lib,
    pkgs,
    mkTools,
    mkEnvironment,
    mkTemplates,
    mkWelcome,
    channel ? "nightly",
  }: let
    inherit (lib.shells) mergeShellSpecs;

    base =
      mergeShellSpecs
      (mkRustSpec {
        inherit lib pkgs mkTools mkEnvironment mkTemplates mkWelcome channel;
      })
      (mkAiSpec {
        inherit lib pkgs;
      });
  in
    mergeShellSpecs base {
      __meta.kind = "combined";
      __meta.sources = ["rust.${channel}" "ai"];

      shell = {
        name = "full-${channel}";
        packages = [];
        env = {};
        shellHook = "";
      };
    };
in {inherit mkRustSpec mkCombinedSpec;}
