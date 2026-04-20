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
    print,
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
    init = ''
      mkdir -p .cargo

      [ -f .cargo/config.toml ] || cp ${templates.cargo}       .cargo/config.toml
      [ -f .envrc ]             || cp ${templates.envrc}       .envrc
      [ -f .gitignore ]         || cp ${templates.gitignore}   .gitignore

      [ -f treefmt.toml ]            && mv treefmt.toml            .treefmt.toml
      [ -f .treefmt.toml ]           || cp ${templates.treefmt}    .treefmt.toml

      [ -f markdownlint-cli2.yaml ]  && mv markdownlint-cli2.yaml  .markdownlint-cli2.yaml
      [ -f .markdownlint-cli2.yaml ] || cp ${templates.markdownlint} .markdownlint-cli2.yaml

      [ -f mise.toml ]               && mv mise.toml               .mise.toml
      [ -f .mise.toml ]              || cp ${templates.mise}        .mise.toml

      chmod +w ${files.keep} 2>/dev/null || true
      git rm -r --cached .direnv target 2>/dev/null || true
      git rm --cached ${files.drop} 2>/dev/null || true

      if ! direnv status 2>/dev/null | grep -q "Found RC allowed 2"; then
        ${cmd.yn} "Allow direnv?" && direnv allow .envrc 2>/dev/null || true
      fi
    '';
  in {
    __meta = {
      kind = "rust";
      package = mkRust {inherit pkgs channel targets extensions;};
      inherit channel templates tools welcome pkgs;
    };

    shell = {
      name = "rust-${channel}";
      packages = tools.packages ++ optionals isDarwin [pkgs.libiconv];
      env = env;
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
in {inherit mkRustSpec;}
