/**
Shared CPU records for the test suites.

Each record is a canonical CPU: `arch`, `brand`, `family`, `model`, `flags`.
Family and model are decimal. Flag sets are cumulative, matching the ladder in
`kernel.nix`: V3 includes V2, V4 includes V3.
*/
let
  makeCpu = arch: brand: family: model: flags: {
    inherit arch brand family model flags;
  };

  flagsV2 = ["sse4_2" "popcnt" "cx16"];
  flagsV3 = flagsV2 ++ ["avx2" "bmi2" "fma" "movbe" "lahf_lm"];
  flagsV4 = flagsV3 ++ ["avx512f" "avx512bw" "avx512dq" "avx512vl"];

  cpus = {
    intelV2 = makeCpu "x86_64" "intel" 6 26 flagsV2;
    intelV3 = makeCpu "x86_64" "intel" 6 60 flagsV3;
    intelV4 = makeCpu "x86_64" "intel" 6 60 flagsV4;
    intelBare = makeCpu "x86_64" "intel" null null [];
    # Family 25 on an Intel record: brand must rule zen4 out.
    intelFamily25 = makeCpu "x86_64" "intel" 25 96 flagsV3;
    intelFamily25NoFlags = makeCpu "x86_64" "intel" 25 96 [];

    zen4 = makeCpu "x86_64" "amd" 25 96 flagsV3;
    zen4WithAvx512 = makeCpu "x86_64" "amd" 25 96 flagsV4;
    zen4LowModel = makeCpu "x86_64" "amd" 25 16 flagsV3; # 0x10
    zen4HighModel = makeCpu "x86_64" "amd" 25 116 flagsV3; # 0x74
    zen4Phoenix = makeCpu "x86_64" "amd" 25 160 flagsV3; # 0xa0

    zen3 = makeCpu "x86_64" "amd" 25 68 flagsV3; # this host
    zen3Vermeer = makeCpu "x86_64" "amd" 25 33 flagsV3; # 0x21, in the old wrong list
    zen3Cezanne = makeCpu "x86_64" "amd" 25 80 flagsV3; # 0x50, in the old wrong list
    zen3NoFlags = makeCpu "x86_64" "amd" 25 68 [];
    zen5 = makeCpu "x86_64" "amd" 26 68 flagsV4;
    amdBare = makeCpu "x86_64" "amd" null null [];
    amdFamilyOnly = makeCpu "x86_64" "amd" 25 null flagsV3;

    aarch64 = makeCpu "aarch64" null null null [];
  };
in {inherit makeCpu flagsV2 flagsV3 flagsV4 cpus;}
