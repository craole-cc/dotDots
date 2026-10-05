/**
Tests for `libraries/types/host/cpu.nix`.

Takes the shared args and the harness positionally; returns a list of cases.
*/
args: harness: let
  inherit (args.lix.types.host) cpu;
  inherit (harness) makeCase makeThrowCase cpus;
in [
  # -- cpu.nix parsing ----------------------------------------------------
  (
    makeCase "cpu" "null gives default" {
      inherit (cpu.resolve null) arch brand family model flags;
    }
    cpu.default
  )
  (
    makeCase "cpu" "attrset merges over default" {
      inherit (cpu.resolve {cpu = {brand = "amd";};}) arch brand family;
    } {
      arch = "x86_64";
      brand = "amd";
      family = null;
    }
  )
  (
    makeCase "cpu" "flags default to empty"
    (
      cpu.resolve {cpu = {brand = "amd";};}
    ).flags []
  )
  (
    makeCase "cpu" "valid record has no warnings"
    (
      cpu.resolve cpus.zen4
    ).warnings []
  )
  # `splitString "_"` also splits the underscore inside "x86_64", so this
  # is expected to FAIL until fromString learns to keep the arch whole.
  (
    makeCase "cpu" "string form x86_64_amd_25_96" {
      inherit (cpu.resolve "x86_64_amd_25_96") arch brand family model;
    } {
      arch = "x86_64";
      brand = "amd";
      family = 25;
      model = 96;
    }
  )
  (
    makeCase "cpu" "string form arch only"
    (cpu.resolve "x86_64").arch "x86_64"
  )
  (
    makeCase "cpu" "string form aarch64"
    (cpu.resolve "aarch64_amd").arch "aarch64"
  )
  (
    makeThrowCase "cpu" "unknown arch" (
      cpu.resolve {cpu = {arch = "riscv";};}
    )
  )
  (
    makeThrowCase "cpu" "unknown brand" (
      cpu.resolve {cpu = {brand = "arm";};}
    )
  )
  (
    makeThrowCase "cpu" "model without family" (
      cpu.resolve {cpu = {model = 1;};}
    )
  )
  (
    makeThrowCase "cpu" "flags not a list" (
      cpu.resolve {cpu = {flags = "avx2";};}
    )
  )
  (
    makeThrowCase "cpu" "integer input" (
      cpu.resolve {cpu = 42;}
    )
  )
]
