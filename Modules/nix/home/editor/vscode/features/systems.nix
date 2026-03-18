{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in {
  name = "systems";
  description = "Rust, shell and systems programming extensions";
  default = false;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Rust LSP
        "rust-lang.rust-analyzer"
        #? LLDB debugger for Rust/C++
        "vadimcn.vscode-lldb"
        #? Rust/Go dependency version checker
        "fill-labs.dependi"
        #? shell script formatter
        "mkhl.shfmt"
        #? shell script linter
        "timonwong.shellcheck"
        #? additional shell formatting
        "foxundermoon.shell-format"
        #? improved shell highlighting
        "jeff-hykin.better-shellscript-syntax"
      ];
      userSettings = {
        "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "rust-analyzer.check.command" = "clippy";
        "rust-analyzer.cargo.features" = "all";
        "[shellscript]"."editor.defaultFormatter" = "mkhl.shfmt";
        "[bats]"."editor.defaultFormatter" = "mkhl.shfmt";
        "[dotenv]"."editor.defaultFormatter" = "mkhl.shfmt";
        "lldb.suppressUpdateNotifications" = true;
        "lldb.showDisassembly" = "auto";
        "lldb.dereferencePointers" = true;
        "lldb.consoleMode" = "commands";
      };
    };
}
