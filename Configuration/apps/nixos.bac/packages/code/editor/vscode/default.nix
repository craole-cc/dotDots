{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vscode
    # (vscode-with-extensions.override {
    #   vscodeExtensions = with vscode-extensions;
    #     [
    #       #| Rust
    #       rust-lang.rust-analyzer
    #       serayuzgur.crates

    #       #| TOML
    #       tamasfe.even-better-toml

    #       #| ShellScript
    #       timonwong.shellcheck

    #       #| Nix
    #       vscode-extensions.kamadorueda.alejandra
    #       vscode-extensions.jnoortheen.nix-ide
    #       vscode-extensions.mkhl.direnv

    #       # | Python
    #       ms-python.python

    #       #| Web Development
    #       bradlc.vscode-tailwindcss

    #       #| Utilities
    #       vadimcn.vscode-lldb
    #       formulahendry.code-runner
    #       github.copilot

    #       #| Theme
    #       vscode-icons-team.vscode-icons
    #       antfu.icons-carbon
    #       roman.ayu-next
    #     ];
    # })
  ];
}
