{ config, pkgs, ... }:
let
  mod = "craole";
  inherit (config.system) stateVersion;
in
{
  users.users.${mod} = {
    isNormalUser = true;
    description = "Craole";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  home-manager.users.${mod} = {
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
    home = {
      inherit stateVersion;
      enableNixpkgsReleaseCheck = false;
      packages =
        let
          fontNerd = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
          fontMono = pkgs.stdenv.mkDerivation {
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
              # Copy all TTF files from subdirectories into the font directory
              find $src -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} $out/share/fonts/opentype/ \;
            '';
          };
          fontLilex = pkgs.stdenv.mkDerivation {
            pname = "lilex";
            version = "2.530";
            src = pkgs.fetchurl {
              url = "https://github.com/mishamyrt/Lilex/releases/download/2.530/Lilex.zip";
              sha256 = "sha256-sBn8DaXj7OXHNaoEAhjTuMmUVUbS0zNZi1h7EjembEo=";
            };
            buildInputs = [ pkgs.unzip ];
            unpackPhase = ''
              unzip -j $src
            '';
            installPhase = ''
              mkdir -p $out/share/fonts/truetype
              mv *.ttf $out/share/fonts/truetype/
            '';
          };
          fontSfMono = pkgs.stdenv.mkDerivation {
            pname = "SFMono-Nerd-Font-Ligaturized";
            version = "1.0";
            src = pkgs.fetchFromGitHub {
              owner = "shaunsingh";
              repo = "SFMono-Nerd-Font-Ligaturized";
              rev = "dc5a3e6fcc2e16ad476b7be3c3c17c2273b260ea";
              hash = "sha256-AYjKrVLISsJWXN6Cj74wXmbJtREkFDYOCRw1t2nVH2w=";
            };
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              find $src -type f -name '*.otf' -exec cp {} $out/share/fonts/opentype/ \;
            '';
          };
          fontMonolisa = pkgs.stdenv.mkDerivation {
            pname = "Monolisa";
            version = "2.012";
            src = pkgs.fetchFromGitHub {
              owner = "redyf"; # Correct owner for Monolisa
              repo = "monolisa"; # Correct repo for Monolisa
              rev = "main"; # Use a specific branch or tag if needed
              sha256 = "your_sha256_hash_here"; # Replace with the actual hash
            };
            installPhase = ''
              mkdir -p $out/share/fonts/truetype
              find $src -type f -name '*.ttf' -exec cp {} $out/share/fonts/truetype/ \;
            '';
          };
          fontCartograph = pkgs.stdenv.mkDerivation {
            pname = "CartographCF";
            version = "1.0";
            src = pkgs.fetchFromGitHub {
              owner = "redyf"; # Correct owner for Cartograph
              repo = "cartograph"; # Correct repo for Cartograph
              rev = "main"; # Use a specific branch or tag if needed
              sha256 = "your_sha256_hash_here"; # Replace with the actual hash
            };
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              find $src -type f -name '*.otf' -exec cp {} $out/share/fonts/opentype/ \;
            '';
          };
          fontBerkeley = pkgs.stdenv.mkDerivation {
            pname = "BerkeleyMono";
            version = "1.001";
            src = pkgs.fetchFromGitHub {
              owner = "redyf"; # Correct owner for BerkeleyMono
              repo = "BerkeleyMono"; # Correct repo for BerkeleyMono
              rev = "main"; # Use a specific branch or tag if needed
              sha256 = "your_sha256_hash_here"; # Replace with the actual hash
            };
            installPhase = ''
              mkdir -p $out/share/fonts/truetype
              find $src -type f -name '*.ttf' -exec cp {} $out/share/fonts/truetype/ \;
            '';
          };
        in
        with pkgs;
        [
          #| Fonts
          fontMono
          fontNerd
          fontLilex
          fontSfMono
          fontMonolisa
          fontCartograph
          fontBerkeley
          lexend
          material-design-icons
          material-icons
          noto-fonts-emoji

          #| Apps
          brave
          freetube
          whatsapp-for-linux
          warp-terminal
          via
          # vscode
          vscode-fhs
          qbittorrent
          mpv
          inkscape-with-extensions
          darktable
          ansel
        ];

      sessionVariables = {
        EDITOR = "hx";
        VISUAL = "code";
        BROWSER = "brave";
        PAGER = "bat --paging=always";
        MANPAGER = "bat --paging=always --plain";
      };

      shellAliases = {
        h = "history";
        la = "eza --group-directories-first --git --almost-all  --smart-group --absolute";
        ll = "la --long";
      };
    };
    programs = {
      btop = {
        enable = true;
        settings = {
          color_theme = "nord";
          theme_background = false;
        };
      };
      eza = {
        enable = true;
        #TODO: None of these are working
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--color-scale"
        ];
      };
      git = {
        enable = true;
        userName = "Craole";
        userEmail = "32288735+Craole@users.noreply.github.com";
      };
      helix = {
        enable = true;
        languages = {
          # https://github-wiki-see.page/m/helix-editor/helix/wiki/External-formatter-configuration
          languages = [
            #| Nix
            {
              name = "nix";
              language-servers = [
                "nixd"
                "nil"
              ];
              formatter.command = "nixfmt";
              auto-format = true;
            }

            #| Shell
            {
              name = "bash";
              indent = {
                tab-width = 2;
                unit = "	";
              };
              formatter = {
                command = "shfmt";
                arguments = "--posix --apply-ignore --case-indent --space-redirects --write";
              };
              auto-format = true;
            }

            #| Rust
            {
              name = "rust";
              language-servers = [ "rust-analyzer" ];
              auto-format = true;
            }

            #| Ruby
            {
              name = "ruby";
              language-servers = [
                "rubocop"
                "solargraph"
              ];
              config = {
                solargraph = {
                  diagnostics = true;
                  formatting = false;
                };
              };
              formatter = {
                command = "bundle";
                args = [
                  "exec"
                  "rubocop"
                  "--stdin"
                  "foo.rb"
                  "-a"
                  "--stderr"
                  "--fail-level"
                  "fatal"
                ];
              };

              # formatter = {
              #   command = "bundle";
              #   args = [
              #     "exec"
              #     "stree"
              #     "format"
              #   ];

              #   command = "rubocop";
              #   args = [
              #     "--stdin"
              #     "foo.rb"
              #     "-a"
              #     "--stderr"
              #     "--fail-level"
              #     "fatal"
              #   ];
              #   timeout = 3;
              # };
              auto-format = true;
            }

            #| Python
            {
              name = "python";
              formatter = {
                command = "ruff";
                args = [
                  "format"
                  "--line-length"
                  "88"
                  "-"
                ];
              };

              # formatter = {
              #   command = "black";
              #   args = [
              #     "-"
              #     "-q"
              #   ];
              # };
              auto-format = true;
            }

            #| SQL
            {
              name = "sql";
              formatter = {
                command = "sqlformat";
                args = [
                  "--reindent"
                  "--indent_width"
                  "2"
                  "--keywords"
                  "upper"
                  "--identifiers"
                  "lower"
                  "-"
                ];
              };
            }

            #| Toml
            {
              name = "toml";
              formatter = {
                command = "taplo";
                args = [
                  "format"
                  "-"
                ];
              };
              auto-format = true;
            }

            #| Json
            {
              name = "json";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "json"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "json"
                # ];
              };
              auto-format = true;
            }

            #| Markdown
            {
              name = "markdown";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "markdown"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "md"
                # ];

              };
              auto-format = true;
            }

            #| TypeScript
            {
              name = "typescript";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "typescript"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "ts"
                # ];
              };
              auto-format = true;
            }
            {
              name = "tsx";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "tsx"
                ];
                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "tsx"
                # ];
              };
              auto-format = true;
            }

            #| JavaScript
            {
              name = "javascript";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "javascript"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "js"
                # ];
              };
              auto-format = true;
            }
            {
              name = "jsx";
              formatter = {

                command = "prettier";
                args = [
                  "--parser"
                  "jsx"
                ];

                # command = "deno";
                # args = [
                #   "fmt"
                #   "-"
                #   "--ext"
                #   "jsx"
                # ];
              };
              auto-format = true;
            }
          ];
        };
        settings = {
          editor = {
            auto-save = true;
            auto-format = true;
            bufferline = "never";
            cursorline = true;
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            statusline = {
              left = [
                "mode"
                "spinner"
                "spacer"
                "file-modification-indicator"
              ];
              center = [ "file-name" ];
              right = [
                "diagnostics"
                "version-control"
                "selections"
                "position"
                "file-encoding"
              ];
              mode = {
                normal = "NORMAL";
                insert = "INSERT";
                select = "SELECT";
              };
              separator = "│";
            };
            idle-timeout = 50;
            line-number = "relative";
            lsp = {
              auto-signature-help = true;
              display-inlay-hints = true;
              display-messages = true;
              display-signature-help-docs = true;
              snippets = true;
            };
            indent-guides = {
              render = true;
              character = "╎"; # "▏", "╎", "┆", "┊", "⸽"
              skip-levels = 1;
              rainbow-option = "normal";
            };
            mouse = false;
            soft-wrap = {
              enable = true;
              wrap-at-text-width = true;
            };
            text-width = 120;
          };
          keys = {
            normal = {
              space = {
                space = "file_picker_in_current_directory";
              };
              "C-]" = "indent";
              C-s = ":write";
              C-S-esc = "extend_line";
              # C-S-o = ":config-open";
              # C-S-r = ":config-reload";
              # a = "move_char_left";
              # w = "move_line_up";
              A-j = [
                "extend_to_line_bounds"
                "delete_selection"
                "paste_after"
              ];
              A-k = [
                "extend_to_line_bounds"
                "delete_selection"
                "move_line_up"
                "paste_before"
              ];
              ret = [
                "open_below"
                "normal_mode"
              ];
              g.u = ":lsp-restart";
              esc = [
                "collapse_selection"
                "keep_primary_selection"
              ];
              A-e = [
                "collapse_selection"
                "keep_primary_selection"
              ];
              A-w = [
                "collapse_selection"
                "keep_primary_selection"
                ":write"
              ];
              A-q = ":quit";
            };

            select = {
              A-e = [
                "collapse_selection"
                "keep_primary_selection"
                "normal_mode"
              ];
              A-w = [
                "collapse_selection"
                "keep_primary_selection"
                "normal_mode"
                ":write"
              ];
              A-q = [
                "normal_mode"
                ":quit"
              ];
            };

            insert = {
              A-space = "normal_mode";
              A-e = "normal_mode";
              A-w = [
                "normal_mode"
                ":write"
              ];
              A-q = [
                "normal_mode"
                ":quit"
              ];
            };
          };
          theme = "gruvbox-dark";
        };
      };
      ripgrep = {
        enable = true;
        arguments = [
          "--max-columns-preview"
          "--colors=line:style:bold"
        ];
      };
      # vscode = {
      #   enable = true;
      #   package = pkgs.vscode-fhs;
      #   enableUpdateCheck = false;
      #   mutableExtensionsDir = true;
      # };
      skim = {
        enable = true;
        defaultCommand = "rg --files --hidden";
        changeDirWidgetOptions = [
          "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
          "--exact"
        ];
      };
      starship = {
        enable = true;
      };
    };
  };
}
