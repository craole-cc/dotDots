{lib}: let
  inherit (lib.attrsets) genAttrs isAttrs optionalAttrs;
  inherit (lib.lists) findFirst;
  inherit (lib.packages) getSystemOrDefault defineSystems;
  inherit (lib.strings) isString isPath;
  inherit (lib.trivial) isFunction isNotEmpty isEmpty;

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
    extraOverlays ? [],
  }: let
    packages = resolvePackages inputs;

    system' =
      if isNotEmpty system
      then system
      else getSystemOrDefault;
  in
    if isEmpty inputs
    then import <nixpkgs> {inherit system;}
    else
      import packages.nix {
        system = system';
        overlays =
          [
            (resolveOverlay packages.ai)
            (resolveOverlay packages.openclaw)
            (resolveOverlay packages.rust)
          ]
          ++ extraOverlays;
        config.allowUnfree = true;
      };

  mkPkgsPerSystem = {inputs, ...}:
    (genAttrs (defineSystems {})) (
      system: mkPkgs {inherit inputs system;}
    );

  parseInput = {
    inputs ? null,
    names,
    error ? "",
  }: let
    inputs' = optionalAttrs (inputs != null) inputs;
    foundName = findFirst (name: inputs' ? ${name}) null names;
    result =
      if foundName != null
      then inputs'.${foundName}
      else null;
  in
    if (isEmpty result) && (isNotEmpty error)
    then throw error
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
  resolvePackages = inputs: let
  in {
    nix = parseInput {
      inherit inputs;
      names = [
        "NixPackagesUnstable"
        "nixpkgs-unstable"
        "NixPackages"
        "nixpkgs-stable"
        "nixpkgs"
      ];
      error = "mkPkgs: Critical dependency 'nixpkgs' not found in inputs.";
    };

    rust = parseInput {
      inherit inputs;
      names = [
        "Rust"
        "RustOverlay"
        "rust-overlay"
        "oxalica"
      ];
    };

    openclaw = parseInput {
      inherit inputs;
      names = [
        "OpenClaw"
        "openclaw"
        "claw"
      ];
    };

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
in {inherit mkPkgs mkPkgsPerSystem;}
