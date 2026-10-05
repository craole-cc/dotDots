/**
Tests for the real host built in the root `default.nix` (`args.host`).

Asserts invariants, not values, so changing the host's data does not break
these. Add checks here as more of the host record gets resolved.
*/
args: harness: let
  inherit (harness) makeCase;
  inherit (args) lix host;
  inherit (lix.types.host) cpu kernel;
  inherit (lix.strings) hasInfix isString;
  inherit (lix.lists) elem isList;

  resolved = {
    kernel = kernel.resolve host;
    cpu = cpu.resolve host;
  };
in [
  (
    makeCase "kernel" "name resolves to a string"
    (isString resolved.kernel.name)
    true
  )
  (
    makeCase "kernel" "warnings is a list"
    (isList resolved.kernel.warnings)
    true
  )
  (
    makeCase "kernel" "level, when set, appears in the name"
    (
      (resolved.kernel.level == null)
      || hasInfix resolved.kernel.level resolved.kernel.name
    )
    true
  )
  (
    makeCase "kernel" "vendor is known"
    (elem resolved.kernel.vendor ["nixpkgs" "cachyos"])
    true
  )
  (
    makeCase "cpu" "arch is known"
    (elem resolved.cpu.arch cpu.arches)
    true
  )
  (
    makeCase "cpu" "flags is a list"
    (isList resolved.cpu.flags)
    true
  )
]
