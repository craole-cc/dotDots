{ config, pkgs, ... }:
let
  inherit (config) DOTS;
  inherit (DOTS.libs) native;
  inherit (native.options) mkOption;
  inherit (native.types)
    listOf
    package
    either
    path
    int
    nonEmptyListOf
    nullOr
    str
    submodule
    ;
  inherit (pkgs) fetchFromGitHub;

  base = "interface";
  mod = "fonts";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = {
    nerdfonts = {
      fonts = mkOption {
        description = "Fonts to install from nerdfonts";
        default = [ "JetBrainsMono" ];
        type = listOf (either package str);
      };
      package = mkOption {
        description = "The font package to use.";
        default = pkgs.nerdfonts.override { fonts = cfg.nerdfonts.fonts; };
        type = either package path;
      };
    };

    awesome = {
      package = mkOption {
        description = "The font package to use";
        default = fetchFromGitHub {
          owner = "rng70";
          repo = "Awesome-Fonts";
          rev = "3733f56e431608878d6cbbf2d70d8bf36ab2c226";
          sha256 = "0m41gdgp06l5ymwvy0jkz6qfilcz3czx416ywkq76z844y5xahd0";
        };
        type = either package path;
      };
    };

    console = {
      size = mkOption {
        description = "Font size";
        default = 14;
        type = int;
      };

      packages = mkOption {
        description = "The font to use in the console";
        default = [ pkgs.terminus_font ];
        type = listOf package;
      };

      font = mkOption {
        description = "The font to use in the console";
        default = "ter-u${toString (cfg.console.size + 10)}n";
        type = str;
      };

      sets = mkOption {
        description = "Fonts to use in the console";
        default = [
          {
            name = "JetBrainsMono Nerd Font";
            package = cfg.nerdfonts.package;
          }
          {
            name = "Source Code Pro";
            package = pkgs.source-code-pro;
          }
        ];
        type =
          let
            font = submodule {
              options = {
                name = mkOption {
                  description = "Font name, as used by fontconfig.";
                  type = str;
                };
                package = mkOption {
                  description = "Package providing the font.";
                  type = package;
                };
              };
            };
          in
          nonEmptyListOf font;
      };
    };

    packages = mkOption {
      description = "The font packages to use.";
      default = with pkgs; [
        nerdfonts.package
        awesome.package

        lexend
        material-design-icons
        material-icons
        noto-fonts-emoji
      ];
      type = listOf package;
    };

    monospace = mkOption {
      description = "The monospace fonts to use.";
      default = [
        "Operator Mono Lig Medium"
        "Operator Mono Lig"
        "Cascadia Code PL"
        "JetBrainsMono Nerd Font"
        "vscodeIcons"
        "Noto Color Emoji"
      ];
      type = listOf str;
    };

    sansSerif = mkOption {
      description = "The sans-serif fonts to use.";
      default = [
        "Lexend"
        "Noto Color Emoji"
      ];
      type = listOf str;
    };

    serif = mkOption {
      description = "The serif fonts to use.";
      default = [
        "Noto Serif"
        "Noto Color Emoji"
      ];
      type = listOf str;
    };

    emoji = mkOption {
      type = listOf str;
      default = [ "Noto Color Emoji" ];
      description = "The emoji fonts to use.";
    };

    gtk = {
      name = mkOption {
        description = "The name of the GTK font";
        default = "Sans";
        type = nullOr str;
      };
      size = mkOption {
        description = "The size of the GTK font";
        default = 10;
        type = nullOr int;
      };
      package = mkOption {
        description = "The package providing the GTK font";
        default = null;
        type = nullOr package;
      };
    };
  };
}
