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
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
  }: let
    inherit (lib.attrsets) optionalAttrs;
    inherit (lib.lists) optionals;
    inherit (lib.packages) mkRust;
    inherit (pkgs.stdenv) isDarwin;

    name = "rust-${channel}";
    rust = mkRust {
      inherit
        pkgs
        channel
        targets
        extensions
        ;
    };
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
    env = {};
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
      ++ optionals includeEditor [
        helix
        jetbrains.rust-rover
      ]
      ++ optionals isDarwin [libiconv];
    shellHook = ''

    '';
  in {
    __meta = {
      kind = "rust";
      inherit
        channel
        rust
        tools
        pkgs
        ;
    };

    shell = {inherit name packages env shellHook;};
  };
in {inherit mkRustSpec;}
