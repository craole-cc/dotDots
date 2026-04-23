# Module: packages/overlays/default.nix
# Purpose: Expose openclaw and gh-tools into the nixpkgs package set.
# Maintainer: openclaw-flake contributors
#
# Why overlays live inside packages/ rather than at the repository root:
#   Overlays are a *composition* of the packages built in sibling directories.
#   They reference built derivations, so they must be evaluated *after* the
#   packages/ tree.  Placing them here (rather than at root) keeps the root
#   clean (only flake.nix + dot-files) and makes the dependency graph explicit:
#   overlays/ depends on packages/openclaw and packages/gh-tools, never the
#   other way around.
{packages}: final: _prev: {
  # Inject the pre-built derivations for the host system.
  # Downstream consumers that import this overlay get the exact derivations
  # that CI built and cached — no recompilation needed.
  openclaw = packages.${final.system}.openclaw;
  gh-tools = packages.${final.system}.gh-tools;
}
