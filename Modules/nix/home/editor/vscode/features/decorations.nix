{
  lix,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  errorLens = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Inline error/warning messages
      "usernamehw.errorlens"
    ];
  };

  indentation = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Colorized indentation guides
      "oderwat.indent-rainbow"
      #? Indentation and scope guides
      "spywhere.guides"
    ];
  };

  colorize = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Colorize CSS color strings
      "kamikillerto.vscode-colorize"
      #? Highlight color values inline
      "naumovs.color-highlight"
    ];
  };

  output = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Colorize output/terminal text
      "ibm.output-colorizer"
      #? ANSI escape code renderer
      "iliazeus.vscode-ansi"
    ];
  };

  lineWidth = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Vertical line width ruler
      "lbragile.line-width-indicator"
    ];
    userSettings = {
      "LWI.breakpoints" = [
        {
          "color" = "rgb(0, 255, 0, 0.6)";
          "column" = 54;
        }
        {
          "color" = "rgb(244, 180, 0, 0.6)";
          "column" = 68;
        }
        {
          "color" = "rgb(255, 0, 0, 0.6)";
          "column" = 79;
        }
      ];
      "LWI.style.fontStyle" = "italic";
      "LWI.style.fontWeight" = "100";
    };
  };

  comments = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Colored comment annotations
      "allemandinstable.colorful-comments-refreshed"
    ];
    userSettings = {
      "colorful-comments-refreshed.tags" = [
        {
          "tag" = "@";
          "italic" = true;
          "backgroundColor" = "#89a25722";
          "color" = "#89a257";
        }
        {
          "tag" = "~@";
          "italic" = true;
          "backgroundColor" = "#89a25722";
          "color" = "#89a257";
        }
        {
          "tag" = "{";
          "italic" = true;
          "backgroundColor" = "#2aaaa222";
          "color" = "#2aaaa2";
        }
        {
          "tag" = "!";
          "backgroundColor" = "transparent";
          "color" = "#ff0000";
        }
        {
          "tag" = "/";
          "italic" = true;
          "backgroundColor" = "#bd8af41a";
          "color" = "#bd8af4";
        }
        {
          "tag" = "|";
          "italic" = true;
          "color" = "hsl(148, 70%, 50%)";
        }
        {
          "tag" = "region";
          "italic" = true;
          "backgroundColor" = "#bd8af41a";
          "color" = "#bd8af4";
        }
        {
          "tag" = "endregion";
          "italic" = true;
          "backgroundColor" = "#bd8af41a";
          "color" = "#bd8af4";
        }
        {
          "tag" = "HELP";
          "italic" = true;
          "backgroundColor" = "transparent";
          "color" = "#fed200";
        }
        {
          "tag" = "shellcheck";
          "italic" = true;
          "backgroundColor" = "transparent";
          "color" = "#fd7b30";
        }
        {
          "tag" = "DOC ";
          "italic" = true;
          "backgroundColor" = "transparent";
          "color" = "#08c3d4";
        }
        {
          "tag" = "USAGE ";
          "italic" = true;
          "backgroundColor" = "transparent";
          "color" = "#08c3d4";
        }
        {
          "tag" = " http";
          "italic" = true;
          "backgroundColor" = "transparent";
          "color" = "#3498DB";
        }
        {
          "tag" = " -- ";
          "bold" = true;
          "backgroundColor" = "transparent";
          "color" = "#3498DB";
        }
        {
          "tag" = ".";
          "bold" = true;
          "backgroundColor" = "transparent";
          "color" = "#3498DB";
        }
        {
          "tag" = "result:";
          "bold" = true;
          "backgroundColor" = "transparent";
          "color" = "#3498DB";
        }
        {
          "tag" = "todo";
          "italic" = true;
          "underline" = true;
          "backgroundColor" = "transparent";
          "color" = "hsla(27, 90%, 55%, 0.75)";
        }
        {
          "tag" = "def";
          "backgroundColor" = "transparent";
          "color" = "hsla(43, 50%, 50%, 0.95)";
        }
        {
          "tag" = "=";
          "backgroundColor" = "transparent";
          "color" = "hsla(335, 80%, 38%, 0.75)";
        }
        {
          "tag" = "+";
          "backgroundColor" = "transparent";
          "color" = "hsla(335, 80%, 38%, 0.75)";
        }
        {
          "tag" = ">";
          "bold" = true;
          "italic" = true;
          "underline" = true;
          "backgroundColor" = "transparent";
          "color" = "hsla(162, 70%, 30%, 0.95)";
        }
        {
          "tag" = "?";
          "bold" = true;
          "italic" = true;
          "underline" = true;
          "backgroundColor" = "transparent";
          "color" = "hsla(162, 70%, 30%, 0.5)";
        }
        {
          "tag" = "╔";
          "italic" = true;
          "backgroundColor" = "hsla(300,86%,47%, 0.15)";
          "color" = "hsl(300,86%,47%)";
        }
        {
          "tag" = "║";
          "italic" = true;
          "backgroundColor" = "hsla(300,86%,47%, 0.15)";
          "color" = "hsl(300,86%,47%)";
        }
        {
          "tag" = "╠";
          "italic" = true;
          "backgroundColor" = "hsla(300,86%,47%, 0.15)";
          "color" = "hsl(300,86%,47%)";
        }
        {
          "tag" = "╚";
          "italic" = true;
          "backgroundColor" = "hsla(300,86%,47%, 0.15)";
          "color" = "hsl(300,86%,47%)";
        }
      ];
    };
  };

  todos = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Highlight TODO/FIXME tokens
      "jgclark.vscode-todo-highlight"
      #? TODO tree sidebar panel
      "gruntfuggly.todo-tree"
    ];
  };
in
{
  name = "decorations";
  description = "Inline highlights, guides and visual aids";
  default = true;
  feature =
    enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        errorLens.extensions
        indentation.extensions
        colorize.extensions
        output.extensions
        lineWidth.extensions
        comments.extensions
        todos.extensions
      ];
      userSettings = mkMerge [
        (errorLens.userSettings or { })
        (indentation.userSettings or { })
        (colorize.userSettings or { })
        (output.userSettings or { })
        (lineWidth.userSettings or { })
        (comments.userSettings or { })
        (todos.userSettings or { })
      ];
    };
}
