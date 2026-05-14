{lib, ...}: let
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
    config ? null,
    extraOverlays ? [],
  }: let
    packages = resolvePackages inputs;
    args =
      {
        config =
          if config != null
          then config
          else {
            allowUnfree = true;
            permittedInsecurePackages = [
              # "openclaw-2026.3.12"
              # "openclaw-2026.5.7"
            ];
          };
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

  # parseInput = {
  #   inputs ? null,
  #   names,
  #   error ? null,
  # }: let
  #   errorMsg =
  #     if isString error
  #     then "mkPkgs: Critical dependency '${error}' not found in inputs."
  #     else "parseInput: could not resolve one of ${toString names} from inputs.";

  #   inputs' = optionalAttrs (inputs != null) inputs;
  #   foundName = findFirst (name: inputs' ? ${name}) null names;
  #   result =
  #     if foundName != null
  #     then inputs'.${foundName}
  #     else null;
  # in
  #   if (isEmpty result) && (isNotEmpty error)
  #   then throw errorMsg
  #   else result;
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
    if foundName == null && isNotEmpty error
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
    fromPath = path: let
      src = import path;
    in
      if isAttrs src
      then src.overlays.default or src.overlay or noop
      else if isFunction src
      then src
      else noop;
  in
    if input == null
    then noop
    else if isAttrs input && input ? overlays
    then input.overlays.default or noop
    else if isAttrs input && input ? overlay
    then input.overlay
    else if isAttrs input && input ? outPath
    then fromPath input.outPath
    else if isFunction input
    then input
    else if isPath input || isString input
    then fromPath input
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
in {
  inherit
    mkOverlays
    mkPkgs
    mkPkgsPerSystem
    parseInput
    perSystem
    resolvePackages
    resolveOverlay
    ;
}
