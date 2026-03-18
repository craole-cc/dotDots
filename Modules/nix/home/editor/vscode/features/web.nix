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

  tailwind = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Tailwind CSS intellisense
      "bradlc.vscode-tailwindcss"
    ];
    userSettings = {
      "tailwindCSS.includeLanguages"."plaintext" = "html";
      "cssvar.files" = [
        "./node_modules/open-props/open-props.min.css"
        "assets/styles/variables.css"
        "style.css"
      ];
      "cssvar.extensions" = ["css" "postcss" "jsx" "tsx"];
      "cssvar.ignore" = [];
    };
  };

  deno = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Deno runtime and LSP
      "denoland.vscode-deno"
    ];
    userSettings = {
      "[javascript]"."editor.defaultFormatter" = "denoland.vscode-deno";
      "[typescript]"."editor.defaultFormatter" = "denoland.vscode-deno";
      "[html]"."editor.defaultFormatter" = "denoland.vscode-deno";
      "typescript.inlayHints.parameterNames.enabled" = "all";
    };
  };

  prettier = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Prettier formatter
      "esbenp.prettier-vscode"
    ];
    userSettings = {
      "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
      "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
      "[scss]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
  };
in {
  name = "web";
  description = "Web development extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        tailwind.extensions
        deno.extensions
        prettier.extensions
      ];
      userSettings = mkMerge [
        (tailwind.userSettings or {})
        (deno.userSettings     or {})
        (prettier.userSettings or {})
      ];
    };
}
