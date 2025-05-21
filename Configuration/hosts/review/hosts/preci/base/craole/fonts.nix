{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      #| Fonts
      (pkgs.stdenv.mkDerivation {
        pname = "Awesome-Fonts";
        version = "1.0";

        src = pkgs.fetchFromGitHub {
          owner = "rng70";
          repo = "Awesome-Fonts";
          rev = "3733f56e431608878d6cbbf2d70d8bf36ab2c226";
          sha256 = "0m41gdgp06l5ymwvy0jkz6qfilcz3czx416ywkq76z844y5xahd0";
        };

        installPhase = ''
          mkdir -p $out/share/fonts/opentype
          find $src -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} $out/share/fonts/opentype/ \;
        '';
      })
      lexend
      material-design-icons
      material-icons
      noto-fonts-emoji
    ]
    ++ (with nerd-fonts; [
      fantasque-sans-mono
      fira-code
      hack
      jetbrains-mono
      monaspace
      monoid
      victor-mono
      zed-mono
    ]);
  fonts.fontconfig = {
    enable = true;
    defaultFonts = rec {
      emoji = [
        "vscodeIcons"
        "Noto Color Emoji"
      ];
      monospace = [
        "Operator Mono Lig Medium"
        "Operator Mono Lig"
        "Cascadia Code PL"
        "JetBrainsMono Nerd Font"
      ] ++ emoji;
      sansSerif = [
        "Lexend"
      ] ++ emoji;
      serif = [
        "Noto Serif"
      ] ++ emoji;
    };
  };
}
