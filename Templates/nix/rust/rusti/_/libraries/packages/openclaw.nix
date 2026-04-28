/**
libraries/packages/openclaw.nix

OpenClaw package selectors and command helpers for lib.packages.
*/
final: prev: {
  /**
  Build OpenClaw package metadata and shell command aliases.

  # Type
  ```nix
  mkOpenClaw :: { pkgs :: AttrSet; } -> {
    package :: derivation;
    bin :: AttrSet;
    cmd :: AttrSet;
  }
  ```

  # Examples
  ```nix
  mkOpenClaw { inherit pkgs; }
  # => {
  #   package = pkgs.openclaw;
  #   bin.openclaw = "/nix/store/.../bin/openclaw";
  #   cmd.claw-ask = "/nix/store/.../bin/openclaw ask";
  # }
  ```

  # Returns
  The OpenClaw package derivation together with binary and command aliases.
  */
  mkOpenClaw = {pkgs}: let
    package = pkgs.openclaw;

    bin = {
      openclaw = "${package}/bin/${package.meta.mainProgram or "openclaw"}";
    };

    cmd = {
      claw = bin.openclaw;
      claw-ask = "${bin.openclaw} ask";
      claw-idx = "${bin.openclaw} index";
      claw-run = "${bin.openclaw} run";
    };
  in {
    inherit package bin cmd;
  };
}
