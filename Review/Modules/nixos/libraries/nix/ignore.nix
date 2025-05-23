{
  config,
  lib,
  ...
}:
let
  #| External libraries
  inherit (lib) mkOption;
  inherit (lib.lists)
    concatMap
    ;
  inherit (lib.strings)
    fileContents
    splitString
    ;

  #| Internal libraries
  mod = "ignore";
  inherit (config) DOTS;
  inherit (DOTS.Libraries.lists) clean infixed suffixed;
in
{
  options.DOTS.Libraries.${mod} = with config.DOTS.Libraries.${mod}; {
    perDot =
      let
        ignore = [
          #| Settings
          ".env"
          ".envrc"
          ".git"
          ".github"
          ".gitlab"
          ".gitignore"
          ".vscode"
          ".sops.yaml"
          ".ignore"

          #| Project
          "LICENSE"
          "README"
          "bin"

          #| Nix
          # "default.nix"
          # "flake.nix"
          # "flake.lock"
          # "shell.nix"
          # "package.nix"
          # "options.nix"
          # "config.nix"
          # "modules.nix"
          # "module.nix"

          #| Temporary
          "review"
          "tmp"
          "temp"
          "result"
          ".Trash-1000"
        ];
      in
      mkOption {
        description = "Process ignore checks based on the .dotignore file at the project root";
        default =
          path:
          clean
            (suffixed {
              list =
                (infixed {
                  list = path;
                  target = map (p: "/" + p + "/") ignore;
                }).inverted;
              target = map (p: "/" + p) ignore;
            }).inverted;
      };

    perGit = mkOption {
      description = "Process ignore checks based on the .gitignore file at the project root";
      default =
        _path:
        let
          lines = concatMap (contents: splitString "\n" contents) (fileContents "/dots/.gitignore");
        in
        # process (map (file: fileContents file) toList (locateProjectRoot + "/.gitignore")) path;
        lines;
    };
  };
}
