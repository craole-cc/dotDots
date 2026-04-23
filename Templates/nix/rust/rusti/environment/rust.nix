{lib, ...}: let
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
    templates,
    pkgs,
    channel ? null,
    targets ? null,
    extensions ? null,
  }: let
    inherit (lib.packages) mkRust;
    inherit (pkgs.stdenv) isDarwin;
    inherit (pkgs.lib.lists) optionals;
    # templates = mkTemplates {inherit pkgs;};
    # tools = mkTools {inherit pkgs rust templates;};
    # env = mkEnvironment {inherit rust channel;};
    # welcome = mkWelcome {inherit pkgs tools;};
    tools = {};
    welcome = {};
    env = {};
  in {
    __meta = {
      kind = "rust";
      package = mkRust {
        inherit
          pkgs
          channel
          targets
          extensions
          ;
      };
      inherit
        channel
        templates
        tools
        welcome
        pkgs
        ;
    };

    shell = {
      name = "rust-${channel}";
      packages = tools.packages ++ optionals isDarwin [pkgs.libiconv];
      inherit env;
      shellHook = ''
        ${tools.init}
        [ -n "$PRJ_HOME" ] || PRJ_HOME=$PWD
        [ -n "$PRJ_NAME" ] || PRJ_NAME=$(basename "$PRJ_HOME")
        RUST_VERSION=$(${tools.rustvv or "unknown"})
        export PRJ_HOME PRJ_NAME RUST_VERSION
        ${welcome}
      '';
    };
  };
in {
  inherit mkRustSpec;
}
