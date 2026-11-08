{pkgs, ...}: let
  description = "Contributor tooling: Rust, Zig and editor language servers";

  packages = with pkgs; [
    cargo # ? Build tool, used by rust-analyzer to discover the workspace
    clippy # ? Rust linter
    rust-analyzer # ? Rust language server
    rust-script # ? Run single-file Rust scripts
    rustc # ? Rust compiler
    rustfmt # ? Rust formatter
    zig_0_15 # ? Matches the compiler pinned in the codex guard hook
    zls_0_15 # ? Zig language server, must match the compiler version
  ];

  #? Lets rust-analyzer find the standard library sources without rustup.
  env.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

  #> Announce the shell, but only in interactive terminals so direnv and scripts stay quiet.
  shellHook = ''
    if [ -t 1 ]; then
      printf "dev shell: rustc %s, zig %s\n" \
        "$(rustc --version | cut -d' ' -f2)" \
        "$(zig version)"
    fi
  '';
in {inherit description packages env shellHook;}
