{lix, ...}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  mkVSCodeFeature {
    extensions = [
      #? basic Nix syntax
      "bbenoist.nix"
      #? Nix LSP, formatting, eval
      "jnoortheen.nix-ide"
      #? improved Nix highlighting
      "jeff-hykin.better-nix-syntax"
      #? direnv environment integration
      "mkhl.direnv"
      #? Alejandra formatter integration
      "kamadorueda.alejandra"
    ];
    userSettings = {
      "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "nix.serverSettings"."nixd" = {
        "formatting"."command" = ["alejandra"];
        "diagnostic"."suppress" = ["sema-primop-overridden"];
      };
      "direnv.restart.automatic" = true;
    };
  }
