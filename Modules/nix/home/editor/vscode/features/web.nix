{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in {
  name = "web";
  description = "Web development extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Tailwind CSS intellisense
        "bradlc.vscode-tailwindcss"
        #? Deno runtime and LSP
        "denoland.vscode-deno"
        #? Prettier formatter
        "esbenp.prettier-vscode"
      ];
      userSettings = {
        "[javascript]"."editor.defaultFormatter" = "denoland.vscode-deno";
        "[typescript]"."editor.defaultFormatter" = "denoland.vscode-deno";
        "[html]"."editor.defaultFormatter" = "denoland.vscode-deno";
        "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
        "[scss]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "typescript.inlayHints.parameterNames.enabled" = "all";
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
}
