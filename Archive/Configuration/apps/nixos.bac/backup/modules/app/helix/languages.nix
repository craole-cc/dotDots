{
  # https://github-wiki-see.page/m/helix-editor/helix/wiki/External-formatter-configuration
  programs.helix.languages.language = [
    {
      name = "nix";
      language-servers = [ "nil" ];
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
}
