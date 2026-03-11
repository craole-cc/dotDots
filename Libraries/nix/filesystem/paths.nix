{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.content.empty) isNotEmpty;
  inherit (_.content.fallback) orDefault firstNonEmpty;
  inherit (lib.filesystem) dirOf;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;

  exports = {
    internal = {
      inherit
        flakeOrNull
        flake
        source
        ;
    };
    external = {
      flakePath = flake;
      flakePathOrNull = flakeOrNull;
      sourcePath = source;
    };
  };

  # ── flakeOrNull ──────────────────────────────────────────────────────────────

  /**
  Try to resolve a flake root path.

  Returns the directory string if the path is a valid flake root, or `null`
  if it cannot be determined. Checks `self.outPath` first (flake context),
  then looks for a `flake.nix` at or under `path`.

  # Type
  ```
  flakeOrNull :: { self? :: AttrSet, path? :: path | string } -> string | null
  ```

  # Examples
  ```nix
  flakeOrNull { self = self; }
  # => "/nix/store/…-source"

  flakeOrNull { path = ./.; }
  # => "/home/…/dotDots"  (if flake.nix exists there)

  flakeOrNull { path = "/nonexistent"; }
  # => null
  ```
  */
  flakeOrNull = {
    self ? {},
    path ? src,
  }: let
    pathStr = toString path;
  in
    if isNotEmpty (self.outPath or null)
    then self.outPath
    else if hasSuffix "/flake.nix" pathStr && pathExists pathStr
    then dirOf pathStr
    else if pathExists (pathStr + "/flake.nix")
    then pathStr
    else null;

  # ── flake ─────────────────────────────────────────────────────────────────

  /**
  Resolve a flake root path, throwing if it cannot be determined.

  Use `flakeOrNull` when you need a null-safe variant.

  # Type
  ```
  flake :: { self? :: AttrSet, path? :: path | string } -> string
  ```

  # Examples
  ```nix
  flake { self = self; }
  # => "/nix/store/…-source"

  flake { path = "/nonexistent"; }
  # => throws "❌ '/nonexistent' is not a valid flake path."
  ```
  */
  flake = {
    self ? {},
    path ? src,
  }:
    orDefault {
      value = flakeOrNull {inherit self path;};
      default = throw "❌ '${toString path}' is not a valid flake path.";
    };

  # ── source ────────────────────────────────────────────────────────────────

  /**
  Build the `nixpkgs` source attribute appropriate for the host class.

  Darwin uses `source`; NixOS uses `flake.source`. Resolves `root` from
  `inputs.nixpkgs` when not explicitly provided.

  # Type
  ```
  source :: { host? :: AttrSet, root? :: any, inputs? :: AttrSet } -> AttrSet
  ```

  # Examples
  ```nix
  source { host.class = "darwin"; inputs.nixpkgs = nixpkgs; }
  # => { source = nixpkgs; }

  source { inputs.nixpkgs = nixpkgs; }
  # => { flake.source = nixpkgs; }
  ```
  */
  source = {
    host ? {},
    root ? null,
    inputs ? {},
    ...
  }:
    if (host.class or "nixos") == "darwin"
    then {source = firstNonEmpty [root (inputs.nixpkgs or null)];}
    else {flake.source = firstNonEmpty [root (inputs.nixpkgs or null)];};
in
  exports.internal // {_rootAliases = exports.external;}
