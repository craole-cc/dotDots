{lib}: let
  inherit (lib.attrsets) attrNames filterAttrs listToAttrs optionaAttrs recursiveUpdate;
  inherit (lib.lists) elem foldl' isList map;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.trivial) functionArgs isNotEmpty;

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
  Merge two *resolved* shell specs (attrsets with `shell` + `__meta`).

  - `packages`  — appended left ++ right
  - `env`       — right wins on conflict (`recursiveUpdate`)
  - `shellHook` — concatenated with a newline separator
  - `name`      — `"left-name+right-name"`, falling back to kind labels
  - `kind`      — `"left-kind+right-kind"`, falling back to whichever exists

  # Type

  mergeSpecs :: AttrSet -> AttrSet -> AttrSet

  text

  # Examples
  ```nix
  mergeSpecs
    { shell.name = "rust-stable"; shell.packages = [pkgs.gcc]; __meta.kind = "rust"; }
    { shell.name = "ai-common";   shell.packages = [pkgs.curl]; __meta.kind = "ai"; }
  # => {
  #   shell.name     = "rust-stable+ai-common";
  #   shell.packages = [ pkgs.gcc pkgs.curl ];
  #   __meta.kind    = "rust+ai";
  # }
  ```
  */
  mergeSpecs = left: right: let
    meta = {
      name = {
        left = left.shell.name   or null;
        right = right.shell.name  or null;
      };
      kind = {
        left = left.__meta.kind  or null;
        right = right.__meta.kind or null;
      };
      shellHook = {
        left = left.shell.shellHook or null;
        right = right.shell.shellHook or null;
      };
      label = {
        left =
          if meta.name.left != null
          then meta.name.left
          else if meta.name.right != null
          then meta.name.right
          else null;
        right =
          if meta.kind.left != null
          then meta.kind.left
          else if meta.kind.right != null
          then meta.kind.right
          else null;
      };
    };

    name =
      if isNotEmpty meta.label.left && isNotEmpty meta.label.right
      then concatStringsSep "+" [meta.label.left meta.label.right]
      else if isNotEmpty meta.label.left
      then meta.label.left
      else if isNotEmpty meta.label.right
      then meta.label.right
      else "unnamed";

    kind =
      if isNotEmpty meta.kind.left && isNotEmpty meta.kind.right
      then concatStringsSep "+" [meta.kind.left meta.kind.right]
      else if isNotEmpty meta.kind.left
      then meta.kind.left
      else if isNotEmpty meta.kind.right
      then meta.kind.right
      else "merged";
  in {
    __meta =
      recursiveUpdate
      (left.__meta or {})
      (right.__meta or {})
      // {inherit kind;};
    shell = {
      inherit name;
      packages =
        (left.shell.packages or [])
        ++ (right.shell.packages or []);

      env =
        recursiveUpdate
        (left.shell.env or {})
        (right.shell.env or {});

      shellHook =
        optionalString
        (isNotEmpty meta.shellHook.left || isNotEmpty meta.shellHook.right) (
          if isNotEmpty meta.shellHook.left && isNotEmpty meta.shellHook.right
          then concatStringsSep "\n" [meta.shellHook.left meta.shellHook.right]
          else if isNotEmpty meta.shellHook.left
          then meta.shellHook.left
          else meta.shellHook.right
        );
    };
  };

  callNamespace = ns: args: let
    declared = attrNames (functionArgs ns.mkShell);
    filtered = filterAttrs (n: _: elem n declared) args;
  in
    ns.mkShell filtered;

  mergeNamespaces = namespaces: let
    ns =
      if isList namespaces
      then
        listToAttrs (map (n: {
            name = n.__meta.kind or "?";
            value = n;
          })
          namespaces)
      else namespaces;

    names = attrNames ns;
    kind = concatStringsSep "+" names;

    mkSpec = args: let
      parts = map (n: callNamespace ns.${n} args) names;
      partNames = map (n: (callNamespace ns.${n} args).shell.name or n) names;
      merged = foldl' mergeSpecs emptySpec parts;
    in
      merged
      // {
        __meta = merged.__meta // {inherit kind;};
        shell = merged.shell // {name = concatStringsSep "+" partNames;};
      };

    mkSuite = {pkgs ? null}: let
      subSuites = map (n:
        optionaAttrs
        (ns.${n} ? mkSuite)
        ns.${n}.mkSuite {inherit pkgs;})
      names;
    in
      foldl' (acc: s: acc // s) {} subSuites;
  in {inherit mkSpec mkSuite;};
in {inherit emptySpec mergeSpecs mergeNamespaces;}
