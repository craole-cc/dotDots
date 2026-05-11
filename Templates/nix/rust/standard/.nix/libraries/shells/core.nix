/**
libraries/shells/build.nix

Shell finalization helpers for lib.shells.
*/
{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    filterAttrs
    isDerivation
    listToAttrs
    mapAttrs
    optionalAttrs
    recursiveUpdate
    ;
  inherit (lib.packages) mkPkgsPerSystem mkPkgs;
  inherit (lib.lists) filter findFirst;
  inherit (lib.lists) elem foldl' isList map;
  inherit (lib.strings) isString concatStringsSep optionalString;
  inherit (lib.trivial) functionArgs isNotEmpty;

  /**
  Turn a shell spec into a `pkgs.mkShell` derivation.

  # Type
  ```nix
  mkShell :: { pkgs :: AttrSet; args :: AttrSet; } -> derivation
  ```

  # Examples
  ```nix
  mkShell {
    pkgs = pkgs.x86_64-linux;
    args = {
      name = "demo";
      packages = [];
      env = {};
      shellHook = "";
    };
  }
  ```
  */
  mkShell = {
    args ? {},
    env ? {},
    inputs ? null,
    name ? "nix-dev",
    packages ? [],
    pkgs ? null,
    shell ? {},
    shellHook ? "",
    system ? null,
    ...
  }: let
    #? Performance note: We use null-check here because pkgs can be huge.
    #? isNotEmpty (nixpkgs) would force evaluation of all attribute names.
    pkgs' =
      if pkgs != null
      then pkgs
      else mkPkgs {inherit inputs system;};

    #> Recursively update or manual merge preserve data.
    args' =
      {inherit name packages;}
      // args
      // shell
      // {
        env = env // (args.env or {}) // (shell.env or {});
        #> Combine hooks rather than overwriting them
        #? Filtering out empty strings and joining with a newline.
        shellHook = concatStringsSep "\n" (
          filter isNotEmpty [
            (shell.shellHook or "")
            shellHook
          ]
        );
      };
  in
    pkgs'.mkShell args';

  mkShells = {
    default ? null,
    inputs ? {},
    shells ? {},
  }:
  #> Iterate over all systems, generating native pkgs for each (Linux & Mac compatibility)
    mapAttrs (
      system: pkgs: let
        #? Ensures each shell gets the correct pkgs and system context
        processShell = spec:
          if isDerivation spec
          then spec
          else
            mkShell {
              inherit pkgs inputs system;
              shell = spec.shell or spec;
            };

        processedShells = mapAttrs (_: processShell) shells;
      in
        processedShells
        // {
          default =
            if default == null
            then let
              found = findFirst isDerivation null (attrValues processedShells);
            in
              if found != null
              then found
              else throw "mkShells: no shells defined and no default provided."
            else if isString default
            then let
              error = throw ''
                mkShells: default shell '${default}' not found.
                Available: ${concatStringsSep ", " (attrNames processedShells)}
              '';
            in
              processedShells.${default} or error
            else processShell default;
        }
    ) (mkPkgsPerSystem {inherit inputs;});

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
        optionalAttrs
        (ns.${n} ? mkSuite)
        ns.${n}.mkSuite {inherit pkgs;})
      names;
    in
      foldl' (acc: s: acc // s) {} subSuites;
  in {inherit mkSpec mkSuite;};
in {
  inherit
    mkShell
    mkShells
    emptySpec
    mergeSpecs
    mergeNamespaces
    ;
}
