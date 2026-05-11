{
  lib,
  paths,
  ...
}: let
  inherit
    (lib.attrsets)
    attrNames
    genAttrs
    isAttrs
    listToAttrs
    nameValuePair
    optionalAttrs
    ;
  inherit (lib.lists) elem filter findFirst head last optional;
  inherit (lib.packages) getSystemOrDefault defineSystems;
  inherit (lib.strings) hasPrefix isString isPath match;
  inherit (lib.trivial) isFunction isNotEmpty isEmpty readDir readFile;

  /**
  Construct a `pkgs` set with the project overlays applied.

  # Type
  ```nix
  mkPkgs :: { inputs :: AttrSet; } -> { system :: string; } -> AttrSet
  ```

  # Examples
  ```nix
  mkPkgs { inherit inputs; } { system = "x86_64-linux"; }
  # => import inputs.NixPackages { ... }
  ```

  # Returns
  A `pkgs` set imported from `inputs.NixPackages` with the project overlays applied.
  */
  mkPkgs = {
    inputs ? null,
    system ? null,
    config ? null,
    extraOverlays ? [],
  }: let
    packages = resolvePackages inputs;
    args =
      {
        config =
          if config != null
          then config
          else {allowUnfree = true;};
        system =
          if isNotEmpty system
          then system
          else getSystemOrDefault {};
      }
      // optionalAttrs (isNotEmpty inputs) {
        overlays = mkOverlays {inherit inputs extraOverlays;};
      };
  in
    if isEmpty inputs
    then import <nixpkgs> args
    else import packages.nix args;

  mkPkgsPerSystem = {inputs, ...}:
    (genAttrs (defineSystems {})) (
      system: mkPkgs {inherit inputs system;}
    );

  parseInput = {
    inputs ? null,
    names,
    error ? null,
  }: let
    errorMsg =
      if isString error
      then "mkPkgs: Critical dependency '${error}' not found in inputs."
      else "parseInput: could not resolve one of ${toString names} from inputs.";

    inputs' = optionalAttrs (inputs != null) inputs;
    foundName = findFirst (name: inputs' ? ${name}) null names;
    result =
      if foundName != null
      then inputs'.${foundName}
      else null;
  in
    if (isEmpty result) && (isNotEmpty error)
    then throw errorMsg
    else result;

  /**
    Resolve specific package set inputs from the flake input attribute set.
    This allows for flexible naming conventions in flake.nix while maintaining
    a consistent internal API.

    # Inputs
    - `inputs`: The attribute set of flake inputs, typically passed from a Nixpkgs overlay or devShell.

    # Type
    ```nix
    resolvePackages :: AttrSet -> AttrSet
    ```

  # Examples
  ```nix
  let
    resolved = resolvePackages inputs;
  in
  resolved.nix # => returns inputs.nixpkgs-unstable or null
  ```

  # Returns
  - An attribute set containing resolved package inputs or null if not found.
  */
  resolvePackages = args: let
    inputs =
      args.inputs or args;
  in {
    ai = parseInput {
      inherit inputs;
      names = [
        "AIAgents"
        "ai-agents"
        "ai-tooling"
        "llm"
        "llm-agents"
        "AI"
        "ai"
      ];
    };

    nix = parseInput {
      inherit inputs;
      names = [
        "NixPackagesUnstable"
        "nixpkgs-unstable"
        "NixPackages"
        "nixpkgs-stable"
        "nixpkgs"
      ];
      error = "nixpkgs";
    };

    openclaw = parseInput {
      inherit inputs;
      names = [
        "claw"
        "OpenClaw"
        "openclaw"
      ];
    };

    rust = parseInput {
      inherit inputs;
      names = [
        "oxalica"
        "rust-overlay"
        "Rust"
        "RustOverlay"
      ];
      error = "rust-overlay";
    };

    treefmt = parseInput {
      inherit inputs;
      names = [
        "fmTree"
        "Formatter"
        "treefmt-nix"
        "TreeFmt"
        "treefmt"
        "TreeFormatter"
      ];
      error = "treefmt-nix";
    };
  };

  /**
  Safely resolves an input into a Nixpkgs overlay.
  Acts as a firewall against broken functors or missing attributes.
  */
  resolveOverlay = input: let
    noop = _: _: {};
  in
    #? 1. Immediate Safety
    if isEmpty input
    then noop
    #? 2. Check for Modern Flake Overlay (overlays.default)
    else if isAttrs input
    then input.overlays.default or noop
    #? 3. Check if the input is already a function
    else if isFunction input
    then input
    #? 4. Fallback for paths (old-school imports)
    else if isPath input || isString input
    then let
      src = import input;
    in
      if isFunction src
      then src
      else noop
    else noop;

  mkOverlays = {
    inputs ? null,
    extraOverlays ? [],
  }: let
    packages = resolvePackages inputs;
  in
    [
      (resolveOverlay packages.ai)
      (resolveOverlay packages.openclaw)
      (resolveOverlay packages.rust)
    ]
    ++ extraOverlays;

  perSystem = {
    fn,
    pkgs ? null,
    inputs ? null,
  }: let
    systems = defineSystems {};
    packages =
      if pkgs != null
      then pkgs
      else mkPkgsPerSystem {inherit inputs;};
  in
    genAttrs systems
    (system: fn packages.${system});

  mkPackages = {
    pkgs,
    dir ? paths.scripts.src or null,
    file ? null,
    files ? [],
    priority ? ["rs" "bash" "sh" "py" "rb"],
  }: let
    dirFiles =
      if dir == null
      then []
      else let
        entries = readDir dir;

        names =
          filter
          (name: entries.${name} == "regular")
          (attrNames entries);
      in
        map
        (name: {
          inherit name;
          path = dir + "/${name}";
        })
        names;

    explicitFiles =
      map
      (path: {
        name = baseNameOf (toString path);
        inherit path;
      })
      (
        files
        ++ optional (file != null) file
      );

    allFiles = dirFiles ++ explicitFiles;

    parseName = name: let
      parts = match "^(.*)\\.([^.]+)$" name;
    in
      if parts == null
      then {
        base = name;
        ext = null;
      }
      else {
        base = head parts;
        ext = last parts;
      };

    scriptName = item:
      (parseName item.name).base;

    scriptExt = item:
      (parseName item.name).ext;

    isSupported = item:
      elem (scriptExt item) priority;

    hasShebang = item:
      hasPrefix "#!" (readFile item.path);

    candidates =
      filter
      (item: isSupported item && hasShebang item)
      allFiles;

    bases = attrNames (
      listToAttrs (
        map
        (item: nameValuePair (scriptName item) true)
        candidates
      )
    );

    choose = base:
      findFirst
      (item: item != null)
      null
      (
        map
        (ext: let
          matches =
            filter
            (item: scriptName item == base && scriptExt item == ext)
            candidates;
        in
          if matches == []
          then null
          else head matches)
        priority
      );

    scriptEnv = ext:
      if ext == "rs"
      then ''
        case "''${RUST_LOG:-}" in
        *rust_script=*)
          ;;
        "") export RUST_LOG="rust_script=warn" ;;
        *) export RUST_LOG="''${RUST_LOG},rust_script=warn" ;;
        esac
      ''
      else "";

    mkDiscoveredScript = base: let
      chosen = choose base;
      ext = scriptExt chosen;

      source = pkgs.writeTextFile {
        name = "${base}-source";
        destination = "/share/${base}/${chosen.name}";
        executable = true;
        text = readFile chosen.path;
      };
    in
      nameValuePair base
      (pkgs.writeShellScriptBin base ''
        ${scriptEnv ext}
        exec ${source}/share/${base}/${chosen.name} "$@"
      '');
  in
    listToAttrs (map mkDiscoveredScript bases);
in {
  inherit
    mkOverlays
    mkPkgs
    mkPkgsPerSystem
    mkPackages
    perSystem
    resolvePackages
    ;
}
