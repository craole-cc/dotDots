{lib}: let
  inherit (lib.packages) mkPkgs mkRust mkBins;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) isNotEmpty;

  mkTools = {
    pkgs ? mkPkgs {},
    rust ? mkRust {inherit pkgs;},
    minimal ? false,
    includeEditor ? true,
    # includeFmt ? true,
    includeWeb ? false,
    includeAnalysis ? true,
    includeWatch ? true,
  }: let
    inherit (lib.shells.mkTools {inherit pkgs;}) print;
    inherit (rust) package channel;
    inherit (pkgs.stdenv) isDarwin;

    tools =
      {
        core =
          {inherit (pkgs) gcc;}
          # // optionalAttrs includeFmt {inherit (pkgs) rustfmt;}
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
          {inherit (pkgs) bacon cargo-watch cargo-make;};
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
        clippy = "${cargo} clippy --all-targets --all-features -- -D warnings";
        fmtrs = "${cargo} fmt --all";
        lint = concatStringsSep " && " (with cmd; [check fmtrs clippy]);
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
      // optionalAttrs (isNotEmpty tools.deps) {
        audit = "${cargo} audit";
        test = "${cargo} nextest run";
        coverage = "${cargo} tarpaulin --out Html --output-dir coverage";
      }
      // optionalAttrs (isNotEmpty tools.editor) {
        rr = bin.rust-rover;
        rrv = ''${bin.rust-rover} --version 2>&1 | head -n1 | awk '{print $2}' '';
      }
      // optionalAttrs (isNotEmpty tools.watch) {
        watch = "${cargo} watch --quiet --clear --exec";
        watch-run = "${cargo} watch --quiet --clear --exec run";
        watch-test = "${cargo} watch --quiet --clear --exec 'nextest run'";
        watch-lint = "${cargo} watch --quiet --clear --exec 'clippy -- -D warnings'";
        baconv = ''${bin.bacon} --version 2>&1 | awk '{print $2}' '';
      }
      // optionalAttrs (isNotEmpty tools.web) {
        leptosfmtv = ''${bin.leptosfmt} --version 2>&1 | cut -d ' ' -f2'';
      }
      // {};
  in {
    inherit bin cmd print;
    tools = tools // {all = tools;};
    # tools = tools // {all = flatten (attrValues tools);};
  };
in {inherit mkTools;}
