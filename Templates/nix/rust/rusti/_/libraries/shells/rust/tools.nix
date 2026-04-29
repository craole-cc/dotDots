{lib}: let
  mkTools = {
    pkgs,
    rust,
    minimal ? false,
    includeEditor ? true,
    includeWeb ? false,
    includeAnalysis ? true,
    includeWatch ? true,
  }: let
    inherit (lib.attrsets) attrValues;
    inherit (lib.lists) optionals flatten;
    inherit (lib.shells.mkTools {inherit pkgs;}) print;
    inherit (lib.trivial) isNotEmpty;
    inherit (rust) package channel;

    tools = {
      core = [rust.package] ++ (with pkgs; [gcc rustfmt]);
      deps =
        optionals (!minimal)
        (with pkgs; [
          cargo-edit
          cargo-outdated
          cargo-audit
          cargo-deny
          cargo-nextest
          cargo-tarpaulin
        ]);
      watch =
        optionals (includeWatch && !minimal)
        (with pkgs; [
          bacon
          cargo-watch
          cargo-make
        ]);
      web =
        optionals (includeWeb && !minimal)
        (with pkgs; [
          cargo-leptos
          trunk
          binaryen
          leptosfmt
        ]);
      analysis =
        optionals (includeAnalysis && !minimal)
        (with pkgs; [
          cargo-flamegraph
          cargo-bloat
          cargo-expand
        ]);
      nightly =
        optionals (channel == "nightly" && !minimal)
        (with pkgs; [cargo-careful]);

      editor = optionals (includeEditor && !minimal) (with pkgs; [
        helix
        jetbrains.rust-rover
      ]);

      darwin = optionals pkgs.stdenv.isDarwin (with pkgs; [libiconv]);
    };

    bin =
      {
        cargo = "${package}/bin/cargo";
        rustc = "${package}/bin/rustc";
        rustfmt = "${pkgs.rustfmt}/bin/rustfmt";
      }
      // optionals (tools.deps != []) {
        nextest = "${pkgs.cargo-nextest}/bin/cargo-nextest";
        tarpaulin = "${pkgs.cargo-tarpaulin}/bin/cargo-tarpaulin";
      }
      // optionals (tools.watch != []) {
        bacon = "${pkgs.bacon}/bin/bacon";
        cargo-watch = "${pkgs.cargo-watch}/bin/cargo-watch";
      }
      // optionals (includeWeb && !minimal) {
        leptosfmt = "${pkgs.leptosfmt}/bin/leptosfmt";
      }
      // optionals (includeEditor && !minimal) {
        rust-rover = "${pkgs.jetbrains.rust-rover}/bin/rust-rover";
      };

    cmd =
      {
        # Core — always present
        bench = "${bin.cargo} bench";
        check = "${bin.cargo} check";
        clippy = "${bin.cargo} clippy --all-targets --all-features -- -D warnings";
        fmtrs = "${bin.rustc} fmt --all";
        lint = "${bin.cargo} fmt --all --check && ${bin.cargo} clippy --all-targets --all-features -- -D warnings";
        run = "${bin.cargo} run";
        rustv = "${bin.rustc} --version | cut -d ' ' -f2";
        rustvv = "${bin.rustc} --version | cut -d ' ' -f2-";
        update-rust = ''
          [ -f Cargo.toml ] &&
            ${print.green} "Updating cargo..." &&
            ${bin.cargo} update
          [ -f Cargo.toml ] || ${print.grey} "Rust project not yet initialized, skipping."
        '';
      }
      // optionals (isNotEmpty tools.deps) {
        audit = "${bin.cargo} audit";
        test = "${bin.cargo} nextest run";
        coverage = "${bin.cargo} tarpaulin --out Html --output-dir coverage";
      }
      // optionals (tools.watch != []) {
        watch = "${bin.cargo} watch --quiet --clear --exec";
        watch-run = "${bin.cargo} watch --quiet --clear --exec run";
        watch-test = "${bin.cargo} watch --quiet --clear --exec 'nextest run'";
        watch-lint = "${bin.cargo} watch --quiet --clear --exec 'clippy -- -D warnings'";
        baconv = ''${bin.bacon} --version 2>&1 | awk '{print $2}' '';
      }
      // optionals (includeWeb && !minimal) {
        leptosfmtv = ''${bin.leptosfmt} --version 2>&1 | cut -d ' ' -f2'';
      }
      // optionals (includeEditor && !minimal) {
        rr = bin.rust-rover;
        rrv = ''${bin.rust-rover} --version 2>&1 | head -n1 | awk '{print $2}' '';
      };
  in {
    inherit bin cmd print;
    tools = tools // {all = flatten (attrValues tools);};
  };
in {inherit mkTools;}
