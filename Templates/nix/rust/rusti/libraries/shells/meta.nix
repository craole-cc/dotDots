/**
libraries/shells/meta.nix

Shell-aware merge logic for lib.shells.
*/
{lib}: let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldl';

  /**
  Empty shell-spec baseline used by merge helpers.

  # Type
  ```nix
  emptySpec :: AttrSet
  ```

  # Examples
  ```nix
  emptySpec
  # => {
  #   __meta = {};
  #   shell = {
  #     name = "unnamed";
  #     packages = [];
  #     env = {};
  #     shellHook = "";
  #   };
  # }
  ```

  # Returns
  The neutral shell spec used as the baseline for shell merges.
  */
  emptySpec = {
    __meta = {};
    shell = {
      name = "unnamed";
      packages = [];
      env = {};
      shellHook = "";
    };
  };

  /**
  Merge two shell specs.

  Metadata and environment values merge recursively; packages append in order;
  shell hooks are concatenated with a newline separator when both exist.

  # Type
  ```nix
  mergeShellSpecs :: AttrSet -> AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mergeShellSpecs
  { shell.packages = [ pkgs.git ]; }
  { shell.packages = [ pkgs.hello ]; }
  # => {
  #   shell.packages = [ pkgs.git pkgs.hello ];
  #   ...
  # }
  ```

  # Returns
  A merged shell spec with recursively combined metadata and environment,
  appended packages, and concatenated shell hooks.
  */
  mergeShellSpecs = left: right: {
    __meta =
      recursiveUpdate
      (left.__meta or {})
      (right.__meta or {});

    shell = {
      name = right.shell.name or left.shell.name or "unnamed";

      packages =
        (left.shell.packages or [])
        ++ (right.shell.packages or []);

      env =
        recursiveUpdate
        (left.shell.env or {})
        (right.shell.env or {});

      shellHook = let
        l = left.shell.shellHook or "";
        r = right.shell.shellHook or "";
      in
        if l == ""
        then r
        else if r == ""
        then l
        else "${l}\n${r}";
    };
  };

  /**
  Merge many shell specs from left to right.

  # Type
  ```nix
  mergeMany :: [AttrSet] -> AttrSet
  ```

  # Examples
  ```nix
  mergeMany [
    { shell.name = "base"; }
    { shell.env.DEBUG = "1"; }
  ]
  # => {
  #   shell.name = "base";
  #   shell.env.DEBUG = "1";
  #   ...
  # }
  ```

  # Returns
  The left-to-right merge of all provided shell specs, starting from `emptySpec`.
  */
  mergeMany = foldl' mergeShellSpecs emptySpec;
in {
  inherit emptySpec mergeShellSpecs mergeMany;
}
