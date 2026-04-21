{lib}: let
  inherit (lib.packages) mkBins;
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
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
  }: let
    inherit (lib.attrsets) optionalAttrs;
    inherit (lib.lists) optionals;
    inherit (lib.packages) mkRust;
    inherit (pkgs.stdenv) isDarwin;

    rust = mkRust {inherit pkgs channel targets extensions;};
    tools = with pkgs;
      {
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
          rustfmt
          taplo
          treefmt
          yamlfmt
          ;
      }
      // optionalAttrs includeEditor {
        #~@ Editor
        inherit helix;
        inherit (jetbrains) rust-rover;
      };

    bin =
      mkBins tools
      // {
        cargo = "${rust}/bin/cargo";
        rustc = "${rust}/bin/rustc";
      };

    cmd =
      {
        inherit rust;
        audit = "${bin.cargo} audit";
        baconv = ''
          ${bin.bacon} --version 2>&1 |
            ${cmd.awk} '{print substr($2, 1)}'
        '';
        bench = "${bin.cargo} bench";
        clippy = "${bin.cargo} clippy -- -D warnings";
        coverage = "${bin.cargo} tarpaulin --out Html --output-dir coverage";
        leptosfmtv = ''${bin.leptosfmt} --version 2>&1 | cut -d ' ' -f2'';
        rustv = "${bin.rustc} --version | cut -d ' ' -f2";
        rustvv = "${bin.rustc} --version | cut -d ' ' -f2-";
        test = "${bin.cargo} nextest run";
        watch = "${bin.cargo} watch --quiet --clear --exec";
        watch-lint = "${cmd.watch} 'clippy -- -D warnings'";
        watch-run = "${cmd.watch} 'run'";
        watch-test = "${cmd.watch} 'nextest run'";
      }
      // optionalAttrs includeEditor {
        rr = bin.rust-rover;
        rrv = ''
          ${cmd.rr} --version 2>&1 | head -n1 |
            ${cmd.awk} '{print substr($2, 1)}'
        '';
      };

    packages = with pkgs;
      [
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
      ]
      ++ optionals includeEditor (with pkgs; [helix jetbrains.rust-rover])
      ++ optionals isDarwin (with pkgs; [libiconv]);
  in {
    __meta = {
      kind = "rust";
      inherit channel rust tools pkgs;
    };

    shell = {
      name = "rust-${channel}";
      packages = packages ++ optionals isDarwin [pkgs.libiconv];
      # env = env;
      shellHook = ''
      '';
    };
  };
in {inherit mkRustSpec;}
