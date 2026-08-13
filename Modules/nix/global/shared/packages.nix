{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) writeShellScriptBin writeShellApplication;
  inherit (lix.lists.construction) optionals;
  inherit (lix.sources.packages) pkgOf pkgsFrom;

  pkgsFor = {
    sources,
    required ? true,
  }:
    pkgsFrom {inherit inputs pkgs required sources;};

  pkgFor = {
    input,
    name ? "default",
    required ? true,
  }:
    pkgOf {inherit input inputs name pkgs required;};

  packages =
    [
      (writeShellScriptBin "is_cmd" ''
        command -v "$@" >/dev/null 2>&1
      '')
      (writeShellApplication {
        name = "finf";
        runtimeInputs = with pkgs; [
          fastfetch
          nitch
          onefetch
          tokei
          git
        ];
        text = ''
          onefetch_min() {
            onefetch \
              --no-art \
              --no-title \
              --no-color-palette \
              --disabled-fields \
                project \
                description \
                head \
                version \
                created \
                languages \
                dependencies \
                authors \
                commits \
                lines-of-code \
                churn \
                size \
                contributors \
                url \
                license
          }

          if [ "''${1:-}" = "--full" ]; then
            nitch
            printf '\n'
            if [ -d .git ]; then
              onefetch
              printf '\n'
            fi
            tokei .
          else
            fastfetch
            printf '\n'
            if [ -d .git ]; then
              onefetch_min
            fi
          fi
        '';
      })
    ]
    ++ (
      with pkgs;
        [
          age #? Encrypting and decrypting files and messages
          alejandra # ? Nix code formatter
          bat # ? Cat clone with syntax highlighting
          direnv # ? Environment variable manager
          fastfetch # ? Fast system information fetcher
          fd # ? Fast find alternative
          gh # ? GitHub CLI
          git # ? Git version control system
          gnused # ? GNU stream editor
          gum # ? Toolkit for building pretty CLI applications
          jq # ? JSON query processor
          lsd # ? LSDeluxe file lister
          nixd # ? Nix language daemon
          onefetch # ? Git repository summary on your terminal
          ripgrep # ? Fast grep alternative
          ripgrep-all # ? Ripgrep, for PDFs, E-Books, Office documents, zip, tar.gz, etc.
          sd # ? Intuitive find & replace CLI (sed alternative)
          sops # ? Secrets OPerationS, for managing secrets
          undollar # ? Remove leading dollar signs age
        ]
        ++ optionals stdenv.isLinux [
          xclip #? Command line interface to the X11 clipboard
          wl-clipboard #? Command line interface to the Wayland clipboard
          xsel #? Command line interface to the X11 selection buffer
        ]
        ++ optionals stdenv.isDarwin [
          pbcopy #? Command line interface to the macOS clipboard
          pbpaste #? Command line interface to the macOS clipboard
        ]
    );
in {inherit packages pkgFor pkgsFor;}
