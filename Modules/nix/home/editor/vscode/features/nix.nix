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

  nixLsp = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? basic Nix syntax
      "bbenoist.nix"
      #? Nix LSP, formatting, eval
      "jnoortheen.nix-ide"
      #? improved Nix highlighting
      "jeff-hykin.better-nix-syntax"
      #? Alejandra formatter integration
      # "kamadorueda.alejandra"
    ];
    userSettings = {
      "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "nix.serverSettings"."nixd" = {
        "formatting"."command" = ["alejandra"];
        "diagnostic"."suppress" = ["sema-primop-overridden"];
      };
    };
  };

  direnv = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? direnv environment integration
      "mkhl.direnv"
    ];
    userSettings = {
      "direnv.restart.automatic" = true;
    };
  };
in {
  name = "nix";
  description = "Nix language and tooling extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        nixLsp.extensions
        direnv.extensions
      ];
      userSettings = mkMerge [
        (nixLsp.userSettings  or {})
        (direnv.userSettings  or {})
      ];
    };
}
