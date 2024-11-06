{ config, pkgs, ... }:
{
  users.users = {
    craole = {
      isNormalUser = true;
      description = "Craole";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [
        vscode-fhs
        warp-terminal
        freetube
        brave
        whatsapp-for-linux
      ];
    };
  };

  home-manager.users = {
    craole = {
      home = {
        inherit (config.system) stateVersion;
        programs = {
          git = {
            enable = true;
            userName = "Craole";
            userEmail = "32288735+Craole@users.noreply.github.com";
          };
          helix = {
            enable = true;
            languages = {
              languages = [
                {
                  name = "nix";
                  language-servers = [ "nixd" ];
                  formatter.command = "nixfmt";
                  auto-format = true;
                }
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
                {
                  name = "rust";
                  language-servers = [ "rust-analyzer" ];
                  auto-format = true;
                }
                {
                  name = "ruby";
                  language-servers = [
                    "rubocop"
                    "solargraph"
                  ];
                  formatter = {
                    command = "bundle";
                    args = [
                      "exec"
                      "stree"
                      "format"
                    ];

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
                  };
                  auto-format = true;
                }
                {
                  name = "python";
                  formatter = {
                    command = "black";
                    args = [
                      "-"
                      "-q"
                    ];
                  };
                  auto-format = true;
                }
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
                {
                  name = "json";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "json"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "markdown";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "md"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "typescript";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "ts"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "tsx";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "tsx"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "javascript";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "js"
                    ];
                  };
                  auto-format = true;
                }
                {
                  name = "jsx";
                  formatter = {
                    command = "deno";
                    args = [
                      "fmt"
                      "-"
                      "--ext"
                      "jsx"
                    ];
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
        };
      };
    };
  };
}
