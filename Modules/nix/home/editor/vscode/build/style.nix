# Launcher-owned workbench styling. The launcher links this stylesheet into
# the writable app copy and adds the <link> tag on every start, so wallpaper
# and surface transparency never depend on an extension re-patching itself
# after a declarative settings change.
{
  pkgs,
  style,
}: let
  opacity = toString style.opacity.editor.${style.mode};

  rules = [
    {
      selector = ".monaco-workbench";
      declarations = {
        position = "relative";
        isolation = "isolate";
        "z-index" = "1";
      };
    }
    {
      selector = ".monaco-workbench, .monaco-workbench .part, .monaco-editor, .monaco-editor-background, .monaco-editor .margin, .monaco-workbench .editor-container";
      declarations."background-color" = "transparent !important";
    }
    {
      selector = ".monaco-workbench::before";
      declarations = {
        content = "''";
        position = "fixed";
        inset = "0";
        "pointer-events" = "none";
        "background-color" = "var(--vscode-editor-background)";
        opacity = "var(--dotdots-editor-opacity, ${opacity})";
        "z-index" = "-1";
      };
    }
    {
      selector = "body:has(div[role=application])";
      declarations.position = "relative";
    }
  ];

  renderDeclaration = name: value: "  ${name}: ${value};";
  render = rule: let
    declarations = rule.declarations;
    lines = map (name: renderDeclaration name declarations.${name}) (builtins.attrNames declarations);
  in "${rule.selector} {\n${builtins.concatStringsSep "\n" lines}\n}\n";
in {
  css = pkgs.writeText "dotdots-workbench.css" (builtins.concatStringsSep "\n" (map render rules));
}
