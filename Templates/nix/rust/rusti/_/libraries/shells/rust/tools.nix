{lib}: let
  inherit (lib.packages) mkPkgs mkRust mkBins;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optional;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) isNotEmpty;

  mkTools = {
    pkgs ? mkPkgs {},
    rust ? mkRust {inherit pkgs;},
    minimal ? false,
    includeEditor ? true,
    includeWeb ? false,
    includeAnalysis ? true,
    includeWatch ? true,
  }: let
    inherit (lib.shells.mkTools {inherit pkgs;}) print;
    inherit
      (rust)
      channel
      hasClippy
      hasLlvmTools
      hasMiri
      hasRustfmt
      package
      ;
    inherit (pkgs.stdenv) isDarwin;

    tools =
      {
        core =
          {inherit (pkgs) gcc;}
          // optionalAttrs isDarwin {inherit (pkgs) libiconv;};
      }
      // optionalAttrs (!minimal) {
        analysis =
          optionalAttrs includeAnalysis
          {
            inherit
              (pkgs)
              cargo-flamegraph
              cargo-bloat
              cargo-expand
              ;
          };
        deps = {
          inherit
            (pkgs)
            cargo-edit
            cargo-outdated
            cargo-audit
            cargo-deny
            cargo-nextest
            cargo-tarpaulin
            ;
        };
        editor = optionalAttrs includeEditor {
          inherit (pkgs) helix;
          inherit (pkgs.jetbrains) rust-rover;
        };
        nightly =
          optionalAttrs (channel == "nightly")
          {inherit (pkgs) cargo-careful;};
        watch =
          optionalAttrs includeWatch
          {inherit (pkgs) bacon cargo-watch cargo-make watchexec;};
        web =
          optionalAttrs includeWeb
          {inherit (pkgs) cargo-leptos trunk binaryen leptosfmt;};
      };

    bin = with tools;
      {
        cargo = "${package}/bin/cargo";
        rustc = "${package}/bin/rustc";
      }
      // optionalAttrs (isNotEmpty analysis) (mkBins analysis)
      // optionalAttrs (isNotEmpty deps) (mkBins deps)
      // optionalAttrs (isNotEmpty editor) (mkBins editor)
      // optionalAttrs (isNotEmpty nightly) (mkBins nightly)
      // optionalAttrs (isNotEmpty watch) (mkBins watch)
      // optionalAttrs (isNotEmpty web) (mkBins web)
      // {};

    cmd = let
      inherit (bin) cargo rustc;
      inherit (print) green grey;
    in
      {
        bench = "${cargo} bench";
        check = "${cargo} check";
        doc = "${cargo} doc --all-features --no-deps";
        run = "${cargo} run";
        rustv = "${rustc} --version | cut -d ' ' -f2";
        rustvv = "${rustc} --version | cut -d ' ' -f2-";
        update = ''
          if [ -f Cargo.toml ]; then
            ${green} "Updating cargo..." ${cargo} update
          else
            ${grey} "Rust project not yet initialized, skipping."
          fi
        '';
      }
      // optionalAttrs hasRustfmt {
        fmtrs = "${cargo} fmt --all";
      }
      // optionalAttrs hasClippy {
        clippy = "${cargo} clippy --all-targets --all-features -- -D warnings";
      }
      // optionalAttrs hasMiri {
        miri = "${cargo} miri test --all-features";
      }
      // optionalAttrs hasLlvmTools {
        coverage = "${cargo} llvm-cov --all-features --workspace";
      }
      // optionalAttrs (isNotEmpty tools.deps) {
        audit = "${cargo} audit";
        test = "${cargo} nextest run";
        coverage = "${cargo} tarpaulin --out Html --output-dir coverage";
      }
      // optionalAttrs (isNotEmpty tools.editor) {
        rr = bin.rust-rover;
        rrv = ''${bin.rust-rover} --version 2>&1 | head -n1 | awk '{print $2}' '';
      }
      // optionalAttrs (isNotEmpty tools.watch) ({
          watch-rs = "${bin.watchexec} --clear --exts rs,toml --";
          watch-cargo = "${cargo} watch --quiet --clear --exec";
          watch-run = "${cmd.watch-rs} '${cmd.run}'";
          watch-lint = "${cmd.watch-rs} '${cmd.lint}'";
          watch-bacon = bin.bacon;
          baconv = ''${bin.bacon} --version 2>&1 | awk '{print $2}' '';
        }
        // optionalAttrs (cmd ? test) {
          watch-test = "${cmd.watch-rs} '${cmd.test}'";
        }
        // optionalAttrs (cmd ? lint) {
          watch-lint = "${cmd.watch-rs} '${cmd.lint}'";
        })
      // optionalAttrs (isNotEmpty tools.web) {
        leptosfmtv = ''${bin.leptosfmt} --version 2>&1 | cut -d ' ' -f2'';
      }
      // {
        lint = concatStringsSep " && " (
          [cmd.check]
          ++ optional (cmd ? fmtrs) cmd.fmtrs
          ++ optional (cmd ? clippy) cmd.clippy
        );
      };
  in {
    inherit bin cmd print;
    tools = tools // {all = tools;};
  };
in {inherit mkTools;}
