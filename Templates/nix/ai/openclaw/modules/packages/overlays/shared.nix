# Module: packages/overlays/shared-nixpkgs.nix
# Purpose: Cross-system overlay that evaluates packages for the host system on demand.
# Maintainer: openclaw-flake contributors
#
# Pattern mirrored from numtide/llm-agents.nix overlays/shared-nixpkgs.nix.
# `mkPackagesFor` is the blueprint-provided function:
#   mkPackagesFor :: system -> attrset of derivations
# The overlay calls it with `final.system` so it always resolves to the
# correct architecture without the caller having to know the system string.
{mkPackagesFor}: final: _prev: let
  pkgsForSystem = mkPackagesFor final.system;
in {
  openclaw = pkgsForSystem.openclaw;
  gh-tools = pkgsForSystem.gh-tools;
}
