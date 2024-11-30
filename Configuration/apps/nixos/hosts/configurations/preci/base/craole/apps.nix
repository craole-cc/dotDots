{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      brave
      whatsapp-for-linux
      warp-terminal
      via
      vscode-fhs
      qbittorrent
      inkscape-with-extensions
      darktable
      ansel
    ];
  };
  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      historyControl = [
        "erasedups"
        "ignoredups"
        "ignorespace"
        "ignoreboth"
      ];
    };
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
    obs-studio = {
      enable = true;
    };
    freetube = {
      enable = true;
    };
    mpv = {
      enable = true;
    };
    atuin = {
      enable = true;
    };
  };
}
