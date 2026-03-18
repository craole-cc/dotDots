{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  rust = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Rust LSP
      "rust-lang.rust-analyzer"
      #? LLDB debugger for Rust/C++
      "vadimcn.vscode-lldb"
      #? Rust/Go dependency version checker
      "fill-labs.dependi"
    ];
    userSettings = {
      "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "rust-analyzer.check.command" = "clippy";
      "rust-analyzer.cargo.features" = "all";
      "lldb.suppressUpdateNotifications" = true;
      "lldb.showDisassembly" = "auto";
      "lldb.dereferencePointers" = true;
      "lldb.consoleMode" = "commands";
    };
  };

  shell = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
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
      "[shellscript]"."editor.defaultFormatter" = "mkhl.shfmt";
      "[bats]"."editor.defaultFormatter" = "mkhl.shfmt";
      "[dotenv]"."editor.defaultFormatter" = "mkhl.shfmt";
    };
  };
in {
  name = "systems";
  description = "Rust, shell and systems programming extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        rust.extensions
        shell.extensions
      ];
      userSettings = mkMerge [
        (rust.userSettings  or {})
        (shell.userSettings or {})
      ];
    };
}
