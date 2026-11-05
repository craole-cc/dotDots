{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  vscode-fhs = mkSource {
    categories = ["editors"];
    description = "VS Code (FHS environment)";
    aliases = mkAliasFamily "code" {
      Add = {
        args = ["--add"];
        description = "add a folder to the last active window";
      };
      Diff = {
        args = ["--diff"];
        description = "compare two files";
      };
      ExtInstall = {
        args = ["--install-extension"];
        description = "install an extension (caller supplies its identifier)";
      };
      ExtList = {
        args = ["--list-extensions"];
        description = "list installed extensions";
      };
      Goto = {
        args = ["--goto"];
        description = "open a file at a caller-specified line and column (file:line:column)";
      };
      New = {
        args = ["--new-window"];
        description = "open in a new window";
      };
      Reuse = {
        args = ["--reuse-window"];
        description = "open in the last active window";
      };
      Safe = {
        args = ["--disable-extensions"];
        description = "start with all extensions disabled";
      };
      Wait = {
        args = ["--wait"];
        description = "wait for the file to be closed before returning";
      };
    };
  };

  vscode-insiders = mkSource {
    categories = ["editors"];
    description = "VS Code Insiders";
    input = "vscode-insiders";
    exe = "code-insiders";
    aliases = mergeDisjoint [
      (mkAliasFamily "code-insiders" {
        aliasPrefix = "codeInsiders";
        Diff = {
          args = ["--diff"];
          description = "compare two files";
        };
        ExtInstall = {
          args = ["--install-extension"];
          description = "install an extension (caller supplies its identifier)";
        };
        ExtList = {
          args = ["--list-extensions"];
          description = "list installed extensions";
        };
        Goto = {
          args = ["--goto"];
          description = "open a file at a caller-specified line and column (file:line:column)";
        };
        New = {
          args = ["--new-window"];
          description = "open in a new window";
        };
        Wait = {
          args = ["--wait"];
          description = "wait for the file to be closed before returning";
        };
      })
    ];
  };
}
