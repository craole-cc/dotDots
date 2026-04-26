{lib}: let
  inherit (lib.lists) elem optionals;
  inherit (lib.shells) mkAliasPackage mkMissionControl mkScriptPackage;
  inherit (lib.packages) mkPkgs mkRust;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.trivial) isEmpty isNotEmpty;

  channels = ["stable" "beta" "nightly"];

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
    pkgs ? null,
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
    minimal ? false,
  }: let
    pkgs' =
      if isNotEmpty pkgs
      then pkgs
      else mkPkgs {};

    rust = mkRust {
      inherit
        channel
        targets
        extensions
        ;
      pkgs = pkgs';
    };
    ch = rust.toolchain.channel;
    inherit (rust) kind;

    name =
      if !elem ch channels
      then throw "mkRustSpec: unknown channel '${ch}'. Valid: ${concatStringsSep ", " channels}"
      else if isEmpty channel
      then "${kind}-${ch}"
      else "rust-${channel}";

    env = {
      CMD_GUM = "${pkgs'.gum}/bin/gum";
      RUST_SRC_PATH = "${rust.package}/lib/rustlib/src/rust/library";
      RUSTFLAGS = optionalString (ch == "nightly") "-Z macro-backtrace";
      RUST_BACKTRACE =
        if ch == "stable"
        then "0"
        else "full";
      RUST_LOG = "info";
      CARGO_INCREMENTAL = "1";
      RUST_CHANNEL = rust.toolchain.channel;
      RUST_TOOLCHAIN_FILE =
        if rust.toolchain.file != null
        then toString rust.toolchain.file
        else "<channel>";
    };

    scripts = {
      commands = mkScriptPackage {
        pkgs = pkgs';
        name = "rust-commands";
        file = ./commands.sh;
      };

      welcome = mkScriptPackage {
        pkgs = pkgs';
        name = "rust-welcome";
        file = ./welcome.sh;
        inherit env;
      };
    };

    # templates = import ../../templates {
    #   lib = lib;
    #   pkgs = pkgs';
    # };

    missionCommands = {
      bench = {
        description = "Run cargo bench";
        run = ''exec rust-command bench "$@"'';
      };
      check = {
        description = "Run cargo check";
        run = ''exec rust-command check "$@"'';
      };
      clippy = {
        description = "Run cargo clippy with warnings denied";
        run = ''exec rust-command clippy "$@"'';
      };
      deploy = {
        description = "Deploy template files into the current project";
        run = ''exec deploy-templates "$@"'';
      };
      fmt = {
        description = "Format the project";
        run = ''exec rust-command fmt "$@"'';
      };
      info = {
        description = "Show project stats and repository summary";
        run = ''exec rust-command info "$@"'';
      };
      lint = {
        description = "Run treefmt, fmt checks, and clippy";
        run = ''exec rust-command lint "$@"'';
      };
      reset = {
        description = "Remove deployed templates and transient build dirs";
        run = ''exec reset-flake "$@"'';
      };
      run = {
        description = "Run cargo run";
        run = ''exec rust-command run "$@"'';
      };
      test = {
        description = "Run cargo nextest";
        run = ''exec rust-command test "$@"'';
      };
      version = {
        description = "Show rustc version";
        run = ''exec rust-command version "$@"'';
      };
      watch-check = {
        description = "Watch cargo check";
        run = ''exec rust-command watch-check "$@"'';
      };
      watch-run = {
        description = "Watch cargo run";
        run = ''exec rust-command watch-run "$@"'';
      };
      watch-test = {
        description = "Watch cargo nextest";
        run = ''exec rust-command watch-test "$@"'';
      };
    };
    missionControl = mkMissionControl {
      pkgs = pkgs';
      shellName = name;
      commands = missionCommands;
    };
    commandsAlias = mkAliasPackage {
      pkgs = pkgs';
      name = "commands";
      target = "${missionControl}/bin/mission-control";
    };
    mcAlias = mkAliasPackage {
      pkgs = pkgs';
      name = "mc";
      target = "${missionControl}/bin/mission-control";
    };

    packages = {
      core = with pkgs'; [rust.package gcc];
      full = optionals (!minimal) (with pkgs'; [
        #~@ Development
        cargo-leptos
        trunk
        binaryen
        #~@ Watch
        bacon
        cargo-watch
        #~@ Dependencies & Security
        cargo-edit
        cargo-outdated
        cargo-audit
        cargo-deny
        #~@ Performance & Analysis
        cargo-flamegraph
        cargo-bloat
        cargo-expand
        #~@ Testing & Quality
        cargo-nextest
        cargo-tarpaulin
        #~@ Formatting
        leptosfmt
        markdownlint-cli2
        prettierd
        rustfmt
        taplo
        treefmt
        yamlfmt
        cargo-make
      ]);
      nightly = optionals (ch == "nightly" && !minimal) (with pkgs'; [cargo-careful]);
      editor = optionals (includeEditor && !minimal) (with pkgs'; [helix jetbrains.rust-rover]);
      darwin = optionals pkgs'.stdenv.isDarwin (with pkgs'; [libiconv]);
    };

    payloadPackages =
      []
      ++ packages.core
      ++ packages.full
      ++ packages.nightly
      ++ packages.editor
      ++ packages.darwin;

    controlPackages = [
      # templates.deployPackage
      # templates.resetPackage
      scripts.commands
      scripts.welcome
      missionControl
      commandsAlias
      mcAlias
    ];

    #> Shell hook includes auto-deployment of templates
    shellHook = ''${scripts.welcome}/bin/rust-welcome'';
    shell = {
      inherit name env shellHook;
      packages = controlPackages ++ payloadPackages;
    };
  in {
    __meta =
      rust
      // shell
      // {
        inherit (scripts) commands;
        inherit controlPackages missionCommands payloadPackages;
      };
    inherit shell;
  };

  mkRustSuite = {pkgs ? null}: let
    mk = args: mkRustSpec ({inherit pkgs;} // args);
  in {
    rust = mk {};

    #~@ Full suite — with editor
    rust-nightly = mk {channel = "nightly";};
    rust-stable = mk {channel = "stable";};
    rust-beta = mk {channel = "beta";};

    #~@ Lean — full tooling, no editor
    rust-nightly-lean = mk {
      channel = "nightly";
      includeEditor = false;
    };
    rust-stable-lean = mk {
      channel = "stable";
      includeEditor = false;
    };

    #~@ Minimal — toolchain + gcc only, no dev tools, no editor
    rust-nightly-minimal = mk {
      channel = "nightly";
      minimal = true;
    };
    rust-stable-minimal = mk {
      channel = "stable";
      minimal = true;
    };
  };
in {
  inherit mkRustSpec mkRustSuite;
  mkRust = mkRustSpec;
  mkRustShells = mkRustSuite;
}
