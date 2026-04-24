{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    ...
  }: let
    inherit (nixpkgs) lib;
    inherit (lib.attrsets) attrValues genAttrs mapAttrs mapAttrsToList;
    inherit (lib.lists) filter optionals;
    inherit (lib.strings) concatStringsSep hasPrefix;

    mkPerSystem = genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    mkDevShell = {
      system,
      channel ? "nightly",
      name ? "roving-rust-${channel}",
    }: let
      pkgs = mkPkgs {inherit system;};
      rust = mkRust {
        inherit channel;
        pkgs = pkgs.rust-bin;
      };
      templates = mkTemplates {inherit pkgs;};
      tools = mkTools {inherit pkgs rust templates;};
      env = mkEnvironment {inherit rust channel;};
      welcome = mkWelcome {inherit pkgs tools;};

      shellHook = ''
        #> Initialize copnfig files
        ${tools.init}

        #> Set runtime environment variables
        [ -n "$PRJ_HOME" ] || PRJ_HOME=$PWD
        [ -n "$PRJ_NAME" ] || PRJ_NAME=$(basename "$PRJ_HOME")
        RUST_VERSION=$(${tools.rustvv})
        export PRJ_HOME PRJ_NAME RUST_VERSION

        #> Display the welcome banner and commands
        ${welcome}
      '';
    in
      pkgs.mkShell {
        inherit shellHook env name;
        inherit (tools) packages;
      };

    mkPkgs = {system}:
      import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
        config.allowUnfree = true;
      };

    mkRust = {
      pkgs,
      channel,
    }: let
      custom = {
        extensions = [
          "rust-src"
          "rust-analyzer"
          "rustfmt"
          "clippy"
        ];
        targets = ["wasm32-unknown-unknown"];
      };

      toolchains = with pkgs; {
        nightly =
          selectLatestNightlyWith
          (t: t.default.override custom);
        beta = beta.latest.default.override custom;
        stable = stable.latest.default.override custom;
      };
    in
      toolchains.${channel};

    mkTools = {
      pkgs,
      rust,
      templates,
    }: let
      files = rec {
        list = [
          ".cargo/config.toml"
          ".envrc"
          ".gitignore"
          ".markdownlint-cli2.yaml"
          ".mise.toml"
          "mise.toml"
          ".treefmt.toml"
          "treefmt.toml"
        ];
        drop = concatStringsSep " " list;
        keep = concatStringsSep " " (filter (hasPrefix ".") list);
      };

      tools = with pkgs; {
        inherit
          #~@ Build Essentials
          gcc
          #~@ Development
          cargo-leptos
          trunk
          binaryen
          #~@ Build & Watch
          cargo-watch
          cargo-make
          bacon
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
          #~@ Git & Project Info
          gitui
          onefetch
          tokei
          #~@ AI
          codex
          bubblewrap
          #~@ Utilities
          gawk
          direnv
          gum
          mise
          trashy
          ;
        #~@ Editor
        inherit helix;
        inherit (jetbrains) rust-rover;
      };

      bin =
        mapAttrs
        (name: drv: "${drv}/bin/${drv.meta.mainProgram or name}")
        tools
        // {
          cargo = "${rust}/bin/cargo";
          rustc = "${rust}/bin/rustc";
        };

      cmd = {
        inherit rust;
        awk = bin.gawk;
        audit = "${bin.cargo} audit";
        baconv = ''
          ${bin.bacon} --version 2>&1 |
            ${cmd.awk} '{print substr($2, 1)}'
        '';
        bench = "${bin.cargo} bench";
        clippy = "${bin.cargo} clippy -- -D warnings";
        commit = ''
          if [ -n "$(git status --porcelain)" ]; then
            ${cmd.yn} "Commit changes?" && ${cmd.gt}
          fi
        '';
        coverage = "${bin.cargo} tarpaulin --out Html --output-dir coverage";
        edit = "\"$VISUAL\" \"$PWD\" > /dev/null 2>&1 & disown";
        green = ''${bin.gum} style --foreground=82'';
        grey = ''${bin.gum} style --foreground=250'';
        gt = "${bin.gitui}";
        info = "${bin.tokei}; ${bin.onefetch}";
        init = ''
          #> Initialize config files
          mkdir -p .cargo

          [ -f .cargo/config.toml ] ||
            cp ${templates.cargo} .cargo/config.toml

          [ -f .envrc ] ||
            cp ${templates.envrc} .envrc

          [ -f .gitignore ] ||
            cp ${templates.gitignore} .gitignore

          [ -f treefmt.toml ] && mv treefmt.toml .treefmt.toml
          [ -f .treefmt.toml ] ||
            cp ${templates.treefmt} .treefmt.toml

          [ -f markdownlint-cli2.yaml ] && mv markdownlint-cli2.yaml .markdownlint-cli2.yaml
          [ -f .markdownlint-cli2.yaml ] ||
            cp ${templates.markdownlint} .markdownlint-cli2.yaml

          [ -f mise.toml ] && mv mise.toml .mise.toml
          [ -f .mise.toml ] ||
            cp ${templates.mise} .mise.toml

          #> Ensure config files are writable
          chmod +w ${files.keep} 2>/dev/null || true

          #> Untrack files that should be ignored
          git rm -r --cached .direnv target 2>/dev/null || true
          git rm --cached ${files.drop} 2>/dev/null || true

          #> Optionally allow direnv
          if ! direnv status 2>/dev/null | grep -q "Found RC allowed 2"; then
            ${cmd.yn} "Allow direnv to automatically reload when changes are detected?" && \
              direnv allow .envrc 2>/dev/null || true
          fi
        '';
        leptosfmtv = ''
          ${bin.leptosfmt} --version 2>&1 | cut -d ' ' -f2
        '';
        lint = ''
          #> Initialize config files
          ${cmd.init}

          #> Commit changes before linting (only if needed)
          ${cmd.commit}

          #> Confirm linting
          ${cmd.yn} "Proceed with linting?" ||
            { ${cmd.yellow} "Linting cancelled."; exit 0; }

          #> Run linters
          failed=0
          ${bin.treefmt}              || failed=1
          ${bin.leptosfmt} **/*.rs    || failed=1
          ${bin.cargo} clippy         || failed=1
          exit $failed
        '';
        magenta = ''${bin.gum} style --foreground=212'';
        markdownlint = bin.markdownlint-cli2;
        markdownlintv = ''
          ${bin.markdownlint-cli2} --version 2>&1 |
            head -1 |
            ${cmd.awk} '{print substr($2, 2)}'
        '';
        misev = ''
          ${bin.mise} version 2>/dev/null |
            grep -oE '^[0-9]+\.[0-9]+\.[0-9]+'
        '';
        prettiest = bin.prettierd;
        prettiestv = ''
          ${cmd.prettiest} --version 2>&1 | cut -d ' ' -f2
        '';
        red = ''${bin.gum} style --foreground=196'';
        reload = ''${bin.direnv} reload'';
        reset = ''
          #> Commit changes before resetting (only if needed)
          ${cmd.commit}

          #> Optionally clean build artifacts
          ${cmd.yn} "Clean cargo build cache?" && ${bin.cargo} clean

          #> Optionally remove lock files
          ${cmd.yn} "Remove lock files? (flake.lock + Cargo.lock)" && {
            ${cmd.trash} flake.lock Cargo.lock 2>/dev/null || true
          }

          #> Remove the existing config files and direnv folder
          ${cmd.yn} "Config files will be re-generated. Continue?" && {
            for f in .direnv ${files.drop}; do
              ${cmd.trash} "$f" 2>/dev/null || true
            done

            #> Remove .cargo if empty
            [ -d .cargo ] && [ -z "$(ls -A .cargo)" ] && \
              ${cmd.trash} .cargo 2>/dev/null || true

            #> Reinitialize
            ${cmd.init}
          }
        '';
        rustv = "${bin.rustc} --version | cut -d ' ' -f2";
        rustvv = "${bin.rustc} --version | cut -d ' ' -f2-";
        rr = bin.rust-rover;
        rrv = ''
          ${cmd.rr} --version 2>&1 | head -n1 |
            ${cmd.awk} '{print substr($2, 1)}'
        '';
        test = "${bin.cargo} nextest run";
        trash = bin.trashy;
        treefmtv = ''
          ${bin.treefmt} --version 2>&1 |
            ${cmd.awk} '{print substr($2, 2)}'
        '';
        update = ''
          ${cmd.yellow} "Updating flake inputs..."
          nix flake update

          if [ -f Cargo.toml ]; then
            ${cmd.green} "Updating cargo dependencies..."
            ${bin.cargo} update
          else
            ${cmd.grey} "No Cargo.toml found, skipping cargo update."
          fi

          ${cmd.magenta} "Done! Reloading shell to apply flake updates."
          direnv reload
        '';
        version = ''
          bacon=$(${cmd.baconv})
          leptosfmt=$(${cmd.leptosfmtv})
          markdownlint=$(${cmd.markdownlintv})
          mise=$(${cmd.misev})
          prettier=$(${cmd.prettiestv})
          rust=$(${cmd.rustvv})
          rover=$(${cmd.rrv})
          treefmt=$(${cmd.treefmtv})

          ${cmd.green} "         Bacon |> $bacon"
          ${cmd.green} "     Leptosfmt |> $leptosfmt"
          ${cmd.green} "  Markdownlint |> $markdownlint"
          ${cmd.green} "          Mise |> $mise"
          ${cmd.green} "      Prettier |> $prettier"
          ${cmd.green} "          Rust |> $rust"
          ${cmd.green} "    Rust-Rover |> $rover"
          ${cmd.green} "       Treefmt |> $treefmt"
        '';
        watch = "${bin.cargo} watch --quiet --clear --exec";
        watch-lint = "${cmd.watch} 'clippy -- -D warnings'";
        watch-run = "${cmd.watch} 'run'";
        watch-test = "${cmd.watch} 'nextest run'";
        yellow = ''${bin.gum} style --foreground=226'';
        yn = ''${bin.gum} confirm'';
      };

      packages =
        [rust]
        ++ (attrValues tools)
        ++ (
          mapAttrsToList
          (name: val: pkgs.writeShellScriptBin name ''${val} "$@"'')
          (removeAttrs cmd ["rust"])
        )
        ++ optionals pkgs.stdenv.isDarwin (with pkgs; [libiconv]);
    in
      {inherit packages;} // cmd;

    mkEnvironment = {
      rust,
      channel,
    }: {
      RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";
      RUST_CHANNEL = channel;
      RUST_BACKTRACE = "full";
      RUST_LOG = "info";
      CARGO_INCREMENTAL = "1";
      VISUAL = "rust-rover";
      EDITOR = "helix";
    };

    mkTemplates = {pkgs}: let
      inherit (pkgs) writeText;
    in {
      cargo = writeText "cargo-config.toml" ''
        [alias]
        b = "build"
        br = "build --release"
        c = "check"
        cl = "clippy"
        t = "test"
        r = "run"
        rr = "run --release"
        w = "watch -x check"
        wr = "watch -x run"

        [build]
        jobs = 4

        [term]
        color = "always"
      '';

      envrc = writeText ".envrc" ''
        use flake
      '';

      gitignore = writeText ".gitignore" ''
        #~@ Rust
        target/
        Cargo.lock
        **/*.rs.bk
        *.pdb

        #~@ Coverage
        coverage/
        *.profraw
        tarpaulin-report.html

        #~@ Environment
        .direnv
        .env
        !.env.example

        #~@ Editor
        .helix/
        .idea/
        .vscode/
        *.swp
        *.swo
        *~

        #~@ OS
        .DS_Store
        Thumbs.db
      '';

      markdownlint = writeText ".markdownlint-cli2.yaml" ''
        config:
          default: true
          MD013:
            line_length: 100
          MD033: false  # Allow inline HTML
          MD041: false  # First line doesn't need to be h1
        fix: true
      '';

      mise = writeText "mise.toml" ''
        [tasks.dev]
        description = "Run in watch mode"
        run = "bacon"

        [tasks.test]
        description = "Run tests"
        run = "cargo nextest run"

        [tasks.coverage]
        description = "Generate coverage report"
        run = "cargo tarpaulin --out Html --output-dir coverage"

        [tasks.bench]
        description = "Run benchmarks"
        run = "cargo bench"

        [tasks.fmt]
        description = "Format all files"
        run = "treefmt"

        [tasks.check]
        description = "Format and clippy"
        run = "treefmt && cargo clippy"

        [tasks.audit]
        description = "Security audit"
        run = "cargo audit"

        [tasks.info]
        description = "Show project info"
        run = "onefetch"

        [tasks.git]
        description = "Open gitui"
        run = "gitui"
      '';

      treefmt = writeText "treefmt.toml" ''
        [global]
        excludes = [".direnv/**", "target/**"]

        [formatter.rust]
        command = "rustfmt"
        options = ["--edition", "2024"]
        includes = ["*.rs"]

        [formatter.toml]
        command = "taplo"
        options = ["format"]
        includes = ["*.toml"]

        [formatter.markdownlint]
        command = "markdownlint"
        options = ["--fix"]
        includes = ["*.md"]
        priority = 1

        [formatter.prettier]
        command = "prettiest"
        options = ["--write"]
        includes = ["*.md", "*.json"]
        priority = 2

        [formatter.yaml]
        command = "yamlfmt"
        includes = ["*.yaml", "*.yml"]
      '';
    };

    mkWelcome = {
      pkgs,
      tools,
    }: let
      inherit (pkgs) writeShellScript;
      inherit (tools) magenta grey rustv;

      mkSection = title: content: ''
        ${magenta} " $ ${title}"
        ${grey} "${concatStringsSep "\n" (map (line: "  ${line}") content)}"
        echo ""
      '';

      mkHeader = title: subtitle: ''
        ${magenta} \
          --border-foreground 212 --border double \
          --align center --width 60 --margin "1 2" --padding "1 2" \
          "${title}" "${subtitle}"
      '';
    in
      writeShellScript "banner.sh" ''
        ${mkHeader "🦀 Rust Development Environment" "Toolchain: $(${rustv})"}

        ${mkSection "Quick Start" [
          "cargo init <name>    # Create new project"
          "cargo new <name>     # Create with git"
          "edit                 # Open project in RustRover"
        ]}

        ${mkSection "Cargo Aliases" [
          "cargo b/br           # build / build --release"
          "cargo c/cl           # check / clippy"
          "cargo t/r/rr         # test / run / run --release"
          "cargo w/wr           # watch check / watch run"
        ]}

        ${mkSection "Watch Commands" [
          "bacon                # Watch mode (default)"
          "watch-run            # cargo watch run"
          "watch-test           # cargo watch nextest"
          "watch-lint           # cargo watch clippy"
        ]}

        ${mkSection "Mise Tasks" [
          "mise dev             # Watch mode with bacon"
          "mise test            # Run tests with nextest"
          "mise coverage        # Generate coverage report"
          "mise fmt             # Format all files"
          "mise audit           # Security audit"
        ]}

        ${mkSection "Shell Commands" [
          "test                 # cargo nextest run"
          "bench                # cargo bench"
          "coverage             # tarpaulin html report"
          "audit                # cargo audit"
          "clippy               # clippy -D warnings"
          "lint                 # treefmt + leptosfmt + clippy"
          "info                 # tokei + onefetch"
          "gt                   # open gitui"
        ]}

        ${mkSection "Environment" [
          "init                 # Initialize config files"
          "reset                # Regenerate config files"
          "reload               # Reload the environment"
          "rustv / rustvv       # Print rust version"
          "update               # Update flake + cargo deps"
          "version              # Show all tool versions"
        ]}
      '';
  in {
    devShells = mkPerSystem (system: let
      for = channel: mkDevShell {inherit system channel;};
      shells = {
        #? Selective shells: nix develop .#stable
        nightly = for "nightly";
        stable = for "stable";
        beta = for "beta";
      };
    in
      shells // {default = shells.nightly;});
  };
}
