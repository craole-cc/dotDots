/**
Tests for `libraries/types/host/kernel.nix`.

Expected values describe the behaviour AFTER the `confirms` fix (flags are
checked against the CPU record) and AFTER the zen4 family/model correction.
A failure therefore means "code and intent disagree", not "test is wrong".

Takes the shared args and the harness positionally; returns a list of cases.
*/
args: harness: let
  lix = args.lix;
  kernel = lix.types.host.kernel;
  cpuLib = lix.types.host.cpu;
  inherit (lix.lists) length;
  inherit (lix.strings) hasInfix;
  inherit (harness) makeCase makeThrowCase;
  inherit (import ./cpus.nix) makeCpu cpus;

  # Positions in `kernel.variants`: zen4, v4, v3, v2, foot.
  confirmsRow = cpuRecord:
    map (entry: kernel.confirms cpuRecord entry) kernel.variants;

  # Reduce a resolve result to the parts worth comparing.
  summarise = resolveArgs: let
    result = kernel.resolve resolveArgs;
  in {
    inherit (result) name vendor level;
    warningCount = length result.warnings;
  };

  expect = name: vendor: level: warningCount: {
    inherit name vendor level warningCount;
  };

  nixpkgsLatest = warningCount:
    expect "linuxPackages_latest" "nixpkgs" null warningCount;
  cachyos = level: warningCount:
    expect "linux-cachyos-${level}" "cachyos" level warningCount;
in [
    # -- levelOf --------------------------------------------------------
    (makeCase "levelOf" "zen4 name" (kernel.levelOf "linux-cachyos-zen4") "zen4")
    (makeCase "levelOf" "v4 name" (kernel.levelOf "linux-cachyos-x86_64-v4") "x86_64-v4")
    (makeCase "levelOf" "v3 name" (kernel.levelOf "linux-cachyos-x86_64-v3") "x86_64-v3")
    (makeCase "levelOf" "v2 name" (kernel.levelOf "linux-cachyos-x86_64-v2") "x86_64-v2")
    (makeCase "levelOf" "nixpkgs name" (kernel.levelOf "linuxPackages_latest") null)
    (makeCase "levelOf" "bare cachyos" (kernel.levelOf "cachyos") null)
    (makeCase "levelOf" "cachyos without level" (kernel.levelOf "linux-cachyos") null)
    (makeCase "levelOf" "other flavour" (kernel.levelOf "linux-cachyos-bore") null)

    # -- unoptimised ----------------------------------------------------
    (makeCase "unoptimised" "nixpkgs" (kernel.unoptimised "linuxPackages_latest") true)
    (makeCase "unoptimised" "cachyos zen4" (kernel.unoptimised "linux-cachyos-zen4") false)

    # -- isBetterThan ---------------------------------------------------
    (makeCase "isBetterThan" "v3" (kernel.isBetterThan "x86_64-v3") ["zen4" "x86_64-v4"])
    (makeCase "isBetterThan" "v4" (kernel.isBetterThan "x86_64-v4") ["zen4"])
    (makeCase "isBetterThan" "v2" (kernel.isBetterThan "x86_64-v2") ["zen4" "x86_64-v4" "x86_64-v3"])
    (makeCase "isBetterThan" "zen4 is best" (kernel.isBetterThan "zen4") [])
    (makeCase "isBetterThan" "null is the foot" (kernel.isBetterThan null) ["zen4" "x86_64-v4" "x86_64-v3" "x86_64-v2"])
    (makeCase "isBetterThan" "unknown level yields whole ladder" (kernel.isBetterThan "bogus") ["zen4" "x86_64-v4" "x86_64-v3" "x86_64-v2" null])

    # -- better ---------------------------------------------------------
    (makeCase "better" "v3 -> zen4" (kernel.better "linux-cachyos-x86_64-v3") "zen4")
    (makeCase "better" "zen4 is best" (kernel.better "linux-cachyos-zen4") null)
    (makeCase "better" "nixpkgs -> zen4" (kernel.better "linuxPackages_latest") "zen4")

    # -- describe -------------------------------------------------------
    (makeCase "describe" "names the kernel" (hasInfix "'linux-cachyos-x86_64-v3'" (kernel.describe {name = "linux-cachyos-x86_64-v3";})) true)
    (makeCase "describe" "names the level" (hasInfix "targets level 'x86_64-v3'" (kernel.describe {name = "linux-cachyos-x86_64-v3";})) true)
    (makeCase "describe" "lists alternatives" (hasInfix "zen4" (kernel.describe {name = "linux-cachyos-x86_64-v3";})) true)
    (makeCase "describe" "explicit level overrides" (hasInfix "targets level 'zen4'" (kernel.describe {
        name = "anything";
        level = "zen4";
      }))
      true)

    # -- fromString -----------------------------------------------------
    (makeCase "fromString" "nixpkgs" (kernel.fromString "linuxPackages_latest") {
      name = "linuxPackages_latest";
      vendor = "nixpkgs";
      level = null;
    })
    (makeCase "fromString" "cachyos zen4" (kernel.fromString "linux-cachyos-zen4") {
      name = "linux-cachyos-zen4";
      vendor = "cachyos";
      level = "zen4";
    })
    (makeCase "fromString" "bare cachyos" (kernel.fromString "cachyos") {
      name = "cachyos";
      vendor = "cachyos";
      level = null;
    })
    (makeCase "fromString" "bare cachy" (kernel.fromString "cachy") {
      name = "cachy";
      vendor = "cachyos";
      level = null;
    })
    (makeCase "fromString" "mixed case" (kernel.fromString "CachyOS") {
      name = "CachyOS";
      vendor = "cachyos";
      level = null;
    })
    (makeCase "fromString" "unknown name is nixpkgs" (kernel.fromString "whatever") {
      name = "whatever";
      vendor = "nixpkgs";
      level = null;
    })

    # -- confirms: one row per CPU, order is zen4 v4 v3 v2 foot ----------
    (makeCase "confirms" "intelV2" (confirmsRow cpus.intelV2) [false false false true true])
    (makeCase "confirms" "intelV3" (confirmsRow cpus.intelV3) [false false true true true])
    (makeCase "confirms" "intelV4" (confirmsRow cpus.intelV4) [false true true true true])
    (makeCase "confirms" "intelBare" (confirmsRow cpus.intelBare) [false false false false true])
    (makeCase "confirms" "intelFamily25 (brand blocks zen4)" (confirmsRow cpus.intelFamily25) [false false true true true])
    (makeCase "confirms" "intelFamily25NoFlags" (confirmsRow cpus.intelFamily25NoFlags) [false false false false true])
    (makeCase "confirms" "zen4" (confirmsRow cpus.zen4) [true false true true true])
    (makeCase "confirms" "zen4WithAvx512" (confirmsRow cpus.zen4WithAvx512) [true true true true true])
    (makeCase "confirms" "zen4LowModel" (confirmsRow cpus.zen4LowModel) [true false true true true])
    (makeCase "confirms" "zen4HighModel" (confirmsRow cpus.zen4HighModel) [true false true true true])
    (makeCase "confirms" "zen4Phoenix" (confirmsRow cpus.zen4Phoenix) [true false true true true])
    (makeCase "confirms" "zen3 (this host)" (confirmsRow cpus.zen3) [false false true true true])
    (makeCase "confirms" "zen3Vermeer" (confirmsRow cpus.zen3Vermeer) [false false true true true])
    (makeCase "confirms" "zen3Cezanne" (confirmsRow cpus.zen3Cezanne) [false false true true true])
    (makeCase "confirms" "zen3NoFlags" (confirmsRow cpus.zen3NoFlags) [false false false false true])
    (makeCase "confirms" "zen5 (family 26)" (confirmsRow cpus.zen5) [false true true true true])
    (makeCase "confirms" "amdBare" (confirmsRow cpus.amdBare) [false false false false true])
    (makeCase "confirms" "amdFamilyOnly (model missing)" (confirmsRow cpus.amdFamilyOnly) [false false true true true])

    # -- bestFor --------------------------------------------------------
    (makeCase "bestFor" "intelV2" (kernel.bestFor cpus.intelV2) "x86_64-v2")
    (makeCase "bestFor" "intelV3" (kernel.bestFor cpus.intelV3) "x86_64-v3")
    (makeCase "bestFor" "intelV4" (kernel.bestFor cpus.intelV4) "x86_64-v4")
    (makeCase "bestFor" "intelBare" (kernel.bestFor cpus.intelBare) null)
    (makeCase "bestFor" "intelFamily25" (kernel.bestFor cpus.intelFamily25) "x86_64-v3")
    (makeCase "bestFor" "intelFamily25NoFlags" (kernel.bestFor cpus.intelFamily25NoFlags) null)
    (makeCase "bestFor" "zen4" (kernel.bestFor cpus.zen4) "zen4")
    (makeCase "bestFor" "zen4WithAvx512 prefers zen4" (kernel.bestFor cpus.zen4WithAvx512) "zen4")
    (makeCase "bestFor" "zen4LowModel" (kernel.bestFor cpus.zen4LowModel) "zen4")
    (makeCase "bestFor" "zen4HighModel" (kernel.bestFor cpus.zen4HighModel) "zen4")
    (makeCase "bestFor" "zen4Phoenix" (kernel.bestFor cpus.zen4Phoenix) "zen4")
    (makeCase "bestFor" "zen3 caps at v3" (kernel.bestFor cpus.zen3) "x86_64-v3")
    (makeCase "bestFor" "zen3Vermeer is not zen4" (kernel.bestFor cpus.zen3Vermeer) "x86_64-v3")
    (makeCase "bestFor" "zen3Cezanne is not zen4" (kernel.bestFor cpus.zen3Cezanne) "x86_64-v3")
    (makeCase "bestFor" "zen3NoFlags" (kernel.bestFor cpus.zen3NoFlags) null)
    (makeCase "bestFor" "zen5 falls to v4" (kernel.bestFor cpus.zen5) "x86_64-v4")
    (makeCase "bestFor" "amdBare" (kernel.bestFor cpus.amdBare) null)
    (makeCase "bestFor" "aarch64" (kernel.bestFor cpus.aarch64) null)

    # -- bestEntryFor ---------------------------------------------------
    (makeCase "bestEntryFor" "aarch64 is null" (kernel.bestEntryFor cpus.aarch64 == null) true)
    (makeCase "bestEntryFor" "bare x86_64 returns the foot entry" (kernel.bestEntryFor cpus.intelBare).name null)
    (makeCase "bestEntryFor" "v3 returns the full entry" (kernel.bestEntryFor cpus.intelV3).name "x86_64-v3")

    # -- resolve: nothing declared ---------------------------------------
    (makeCase "resolve/none" "v3 CPU" (summarise {cpu = cpus.intelV3;}) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/none" "v4 CPU" (summarise {cpu = cpus.intelV4;}) (cachyos "x86_64-v4" 0))
    (makeCase "resolve/none" "zen4 CPU" (summarise {cpu = cpus.zen4;}) (cachyos "zen4" 0))
    (makeCase "resolve/none" "zen3 CPU" (summarise {cpu = cpus.zen3;}) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/none" "bare CPU warns" (summarise {cpu = cpus.intelBare;}) (nixpkgsLatest 1))
    (makeCase "resolve/none" "aarch64 warns" (summarise {cpu = cpus.aarch64;}) (nixpkgsLatest 1))
    (makeCase "resolve/none" "no cpu key at all" (summarise {}) (nixpkgsLatest 1))
    (makeCase "resolve/none" "cpu under specs" (summarise {specs.cpu = cpus.intelV3;}) (cachyos "x86_64-v3" 0))

    # -- resolve: explicit nixpkgs ----------------------------------------
    (makeCase "resolve/nixpkgs" "on v3 CPU" (summarise {
      cpu = cpus.intelV3;
      kernel = "linuxPackages_latest";
    }) (nixpkgsLatest 0))
    (makeCase "resolve/nixpkgs" "on bare CPU, no warning" (summarise {
      cpu = cpus.intelBare;
      kernel = "linuxPackages_latest";
    }) (nixpkgsLatest 0))
    (makeCase "resolve/nixpkgs" "other nixpkgs kernel kept" (summarise {
      cpu = cpus.intelV3;
      kernel = "linuxPackages_6_6";
    }) (expect "linuxPackages_6_6" "nixpkgs" null 0))

    # -- resolve: bare cachyos --------------------------------------------
    (makeCase "resolve/bare" "cachyos on v3" (summarise {
      cpu = cpus.intelV3;
      kernel = "cachyos";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/bare" "cachy on v3" (summarise {
      cpu = cpus.intelV3;
      kernel = "cachy";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/bare" "CachyOS on v3, legacy field" (summarise {
      cpu = cpus.intelV3;
      packages.kernel = "CachyOS";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/bare" "cachyos on v4" (summarise {
      cpu = cpus.intelV4;
      kernel = "cachyos";
    }) (cachyos "x86_64-v4" 0))
    (makeCase "resolve/bare" "cachyos on zen4" (summarise {
      cpu = cpus.zen4;
      kernel = "cachyos";
    }) (cachyos "zen4" 0))
    (makeCase "resolve/bare" "cachyos on zen3" (summarise {
      cpu = cpus.zen3;
      kernel = "cachyos";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/bare" "cachyos on bare CPU falls back and warns" (summarise {
      cpu = cpus.intelBare;
      kernel = "cachyos";
    }) (nixpkgsLatest 1))
    (makeCase "resolve/bare" "linux-cachyos on v3" (summarise {
      cpu = cpus.intelV3;
      kernel = "linux-cachyos";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/bare" "other flavour is replaced (documented limitation)" (summarise {
      cpu = cpus.intelV3;
      kernel = "linux-cachyos-bore";
    }) (cachyos "x86_64-v3" 0))

    # -- resolve: explicit level, kept as declared -------------------------
    (makeCase "resolve/explicit" "zen4 on v3 CPU kept" (summarise {
      cpu = cpus.intelV3;
      kernel = "linux-cachyos-zen4";
    }) (cachyos "zen4" 0))
    (makeCase "resolve/explicit" "v3 on zen4 CPU kept" (summarise {
      cpu = cpus.zen4;
      kernel = "linux-cachyos-x86_64-v3";
    }) (cachyos "x86_64-v3" 0))
    (makeCase "resolve/explicit" "v4 on bare CPU kept" (summarise {
      cpu = cpus.intelBare;
      kernel = "linux-cachyos-x86_64-v4";
    }) (cachyos "x86_64-v4" 0))

    # -- resolve: field precedence and shapes ------------------------------
    (makeCase "resolve/fields" "kernel beats packages.kernel" (summarise {
      cpu = cpus.intelV3;
      kernel = "linuxPackages_latest";
      packages.kernel = "cachyos";
    }) (nixpkgsLatest 0))
    (makeCase "resolve/fields" "legacy field alone" (summarise {
      cpu = cpus.intelV3;
      packages.kernel = "linuxPackages_latest";
    }) (nixpkgsLatest 0))
    (makeCase "resolve/fields" "pre-resolved record passes through" (summarise {
      cpu = cpus.intelV3;
      kernel = {
        name = "linux-cachyos-zen4";
        vendor = "cachyos";
        level = "zen4";
      };
    }) (cachyos "zen4" 0))
    (makeCase "resolve/fields" "pre-resolved nixpkgs record" (summarise {
      cpu = cpus.intelV3;
      kernel = {
        name = "linuxPackages_latest";
        vendor = "nixpkgs";
        level = null;
      };
    }) (nixpkgsLatest 0))

    # -- resolve: cpu given in other shapes --------------------------------
    (makeCase "resolve/cpu shapes" "partial attrset with family and model confirms zen4" (summarise {
      cpu = {
        brand = "amd";
        family = 25;
        model = 96;
      };
      kernel = "cachyos";
    }) (cachyos "zen4" 0))
    (makeCase "resolve/cpu shapes" "brand-only attrset cannot confirm anything" (summarise {
      cpu = {brand = "amd";};
      kernel = "cachyos";
    }) (nixpkgsLatest 1))
    (makeCase "resolve/cpu shapes" "string arch plus attrset in a list" (summarise {
      cpu = [
        "x86_64_amd"
        {
          family = 25;
          model = 96;
        }
      ];
    }) (cachyos "zen4" 0))
    (makeCase "resolve/cpu shapes" "later list item does not reset earlier fields" (let
      cpuRecord = cpuLib.resolve {
        cpu = [
          {brand = "amd";}
          {
            family = 25;
            model = 96;
          }
        ];
      };
    in {inherit (cpuRecord) brand family model;}) {
      brand = "amd";
      family = 25;
      model = 96;
    })
    (makeCase "resolve/cpu shapes" "list of attrsets merges" (summarise {
      cpu = [
        {brand = "amd";}
        {
          family = 25;
          model = 96;
        }
      ];
    }) (cachyos "zen4" 0))
    (makeCase "resolve/cpu shapes" "null cpu" (summarise {cpu = null;}) (nixpkgsLatest 1))

    # -- resolve: invalid input throws -------------------------------------
    (makeThrowCase "resolve/invalid" "integer kernel"
      (kernel.resolve {
        cpu = cpus.intelV3;
        kernel = 42;
      }).name)
    (makeThrowCase "resolve/invalid" "list kernel"
      (kernel.resolve {
        cpu = cpus.intelV3;
        kernel = ["cachyos"];
      }).name)
    (makeThrowCase "resolve/invalid" "attrset missing level"
      (kernel.resolve {
        cpu = cpus.intelV3;
        kernel = {
          name = "x";
          vendor = "cachyos";
        };
      }).name)
    (makeThrowCase "resolve/invalid" "unknown arch" (kernel.resolve {cpu = makeCpu "riscv" null null null [];}).name)
    (makeThrowCase "resolve/invalid" "unknown brand" (kernel.resolve {cpu = makeCpu "x86_64" "arm" null null [];}).name)
    (makeThrowCase "resolve/invalid" "family without model" (kernel.resolve {cpu = cpus.amdFamilyOnly;}).name)
  # -- cpu records built from other shapes are covered in types/host/cpu.nix
]
