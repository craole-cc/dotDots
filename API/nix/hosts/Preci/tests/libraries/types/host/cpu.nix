/**
Tests for `libraries/types/host/cpu.nix`.

Takes the shared args and the harness positionally; returns a list of cases.
*/
args: harness: let
  cpuLib = args.lix.types.host.cpu;
  inherit (harness) makeCase makeThrowCase;
  inherit (import ./cpus.nix) cpus;
in [
    # -- cpu.nix parsing ----------------------------------------------------
    (makeCase "cpu" "null gives default" (let
      cpuRecord = cpuLib.resolve null;
    in {inherit (cpuRecord) arch brand family model flags;})
    cpuLib.default)
    (makeCase "cpu" "attrset merges over default" (let
      cpuRecord = cpuLib.resolve {cpu = {brand = "amd";};};
    in {inherit (cpuRecord) arch brand family;}) {
      arch = "x86_64";
      brand = "amd";
      family = null;
    })
    (makeCase "cpu" "flags default to empty" (cpuLib.resolve {cpu = {brand = "amd";};}).flags [])
    (makeCase "cpu" "valid record has no warnings" (cpuLib.resolve cpus.zen4).warnings [])
    # `splitString "_"` also splits the underscore inside "x86_64", so this
    # is expected to FAIL until fromString learns to keep the arch whole.
    (makeCase "cpu" "string form x86_64_amd_25_96" (let
      cpuRecord = cpuLib.resolve "x86_64_amd_25_96";
    in {inherit (cpuRecord) arch brand family model;}) {
      arch = "x86_64";
      brand = "amd";
      family = 25;
      model = 96;
    })
    (makeCase "cpu" "string form arch only" (cpuLib.resolve "x86_64").arch "x86_64")
    (makeCase "cpu" "string form aarch64" (cpuLib.resolve "aarch64_amd").arch "aarch64")
    (makeThrowCase "cpu" "unknown arch" (cpuLib.resolve {cpu = {arch = "riscv";};}))
    (makeThrowCase "cpu" "unknown brand" (cpuLib.resolve {cpu = {brand = "arm";};}))
    (makeThrowCase "cpu" "model without family" (cpuLib.resolve {cpu = {model = 1;};}))
    (makeThrowCase "cpu" "flags not a list" (cpuLib.resolve {cpu = {flags = "avx2";};}))
    (makeThrowCase "cpu" "integer input" (cpuLib.resolve {cpu = 42;}))
]
