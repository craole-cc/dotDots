/**
Tests for the real host built in the root `default.nix` (`args.host`).

Asserts invariants, not values, so changing the host's data does not break
these. Add checks here as more of the host record gets resolved.
*/
args: harness: let
  lix = args.lix;
  kernel = lix.types.host.kernel;
  cpuLib = lix.types.host.cpu;
  inherit (harness) makeCase;
  inherit (lix.strings) hasInfix isString;
  inherit (lix.lists) elem;

  resolvedKernel = kernel.resolve args.host;
  resolvedCpu = cpuLib.resolve args.host;
in [
  (makeCase "kernel" "name resolves to a string" (isString resolvedKernel.name) true)
  (makeCase "kernel" "warnings is a list" (builtins.isList resolvedKernel.warnings) true)
  (makeCase "kernel" "level, when set, appears in the name" (resolvedKernel.level == null || hasInfix resolvedKernel.level resolvedKernel.name) true)
  (makeCase "kernel" "vendor is known" (elem resolvedKernel.vendor ["nixpkgs" "cachyos"]) true)
  (makeCase "cpu" "arch is known" (elem resolvedCpu.arch cpuLib.arches) true)
  (makeCase "cpu" "flags is a list" (builtins.isList resolvedCpu.flags) true)
]
