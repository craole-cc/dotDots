{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.attrsets) removeAttrs;
  inherit (lib.lists) elemAt filter imap0 length;
  inherit (lib.strings) replaceStrings splitString;

  vendorMap = {
    "10de" = "nvidia";
    "1002" = "amd";
    "8086" = "intel";
  };

  parseLine = line: let
    parts = splitString " " (replaceStrings ["\""] [" "] line);
    bus = elemAt parts 0;
    class = elemAt parts 2;
    vendor = elemAt parts 5;
    device = elemAt parts 6;
  in {
    busId = "PCI:${replaceStrings [":"] [""] bus}";
    vendorId = vendor;
    deviceId = device;
    brand = vendorMap.${vendor} or "unknown";
    isGPU = class == "0300";
  };

  /**
  Parse `lspci -mm` output into a list of GPU descriptor attrsets.

  Only entries with PCI class `0300` are included. The `isGPU` field is
  stripped from results.

  # Type
  ```nix
  parseLspci :: string -> [{ busId, vendorId, deviceId, brand, index }]
  ```
  */
  parseLspci = lspciOutput: let
    lines = filter (l: l != "") (splitString "\n" lspciOutput);
    parsed = imap0 (i: line: parseLine line // {index = i;}) lines;
    gpus = filter (gpu: gpu.isGPU) parsed;
  in
    map (gpu: removeAttrs gpu ["isGPU"]) gpus;

  /**
  Build a GPU list from `lspci -mm` output, annotating each entry with
  `primary = false` and `secondary = false` for downstream assignment.

  # Type
  ```nix
  fromLspciMm :: string -> [AttrSet]
  ```
  */
  fromLspciMm = lspciMm:
    map
    (gpu:
      gpu
      // {
        primary = false;
        secondary = false;
      })
    (parseLspci lspciMm);

  testLspciInput = ''
    01:00.0 "Class 0300" "10de" "25ad" "103c" "8c30"
    02:00.0 "Class 0301" "1234" "abcd" "0000" "0000"
    06:00.0 "Class 0300" "1002" "1681" "103c" "8c30"
    07:00.0 "Class 0302" "8086" "1234" "0000" "0000"
  '';

  exports = {
    inherit fromLspciMm parseLspci testLspciInput vendorMap;
  };
in
  exports
  // {
    _rootAliases = exports;

    _tests = runTests {
      parseLspci = {
        onlyIncludesGPUs = mkTest {
          desired = 2;
          outcome = length (parseLspci testLspciInput);
          command = "length (parseLspci testLspciInput)";
        };
        firstIsNvidia = mkTest {
          desired = "nvidia";
          outcome = (elemAt (parseLspci testLspciInput) 0).brand;
          command = "(elemAt (parseLspci testLspciInput) 0).brand";
        };
        secondIsAmd = mkTest {
          desired = "amd";
          outcome = (elemAt (parseLspci testLspciInput) 1).brand;
          command = "(elemAt (parseLspci testLspciInput) 1).brand";
        };
        correctIndex = mkTest {
          desired = 0;
          outcome = (elemAt (parseLspci testLspciInput) 0).index;
          command = "(elemAt (parseLspci testLspciInput) 0).index";
        };
      };

      fromLspciMm = {
        sameCount = mkTest {
          desired = 2;
          outcome = length (fromLspciMm testLspciInput);
          command = "length (fromLspciMm testLspciInput)";
        };
        primaryFalse = mkTest {
          desired = false;
          outcome = (elemAt (fromLspciMm testLspciInput) 0).primary;
          command = "(elemAt (fromLspciMm testLspciInput) 0).primary";
        };
        secondaryFalse = mkTest {
          desired = false;
          outcome = (elemAt (fromLspciMm testLspciInput) 0).secondary;
          command = "(elemAt (fromLspciMm testLspciInput) 0).secondary";
        };
      };

      vendorMap = {
        hasNvidia = mkTest' "nvidia" vendorMap."10de";
        hasAmd = mkTest' "amd" vendorMap."1002";
        hasIntel = mkTest' "intel" vendorMap."8086";
      };
    };
  }
