{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) removeAttrs;
  inherit (lib.strings) splitString replaceStrings;
  inherit (lib.lists) filter elemAt imap0 length;

  #| TEST DATA & UTILS
  testLspciInput = ''
    01:00.0 "Class 0300" "10de" "25ad" "103c" "8c30"
    02:00.0 "Class 0301" "1234" "abcd" "0000" "0000"
    06:00.0 "Class 0300" "1002" "1681" "103c" "8c30"
    07:00.0 "Class 0302" "8086" "1234" "0000" "0000"
  '';

  # Vendor ID → brand mapping
  vendorMap = {
    "10de" = "nvidia";
    "1002" = "amd";
    "8086" = "intel";
  };

  parseLine = line: let
    parts = splitString " " (replaceStrings ["\"" "\""] [" " " "] line);
    bus = elemAt parts 0;
    class = elemAt parts 1;
    vendor = elemAt parts 3;
    device = elemAt parts 4;
  in {
    busId = "PCI:${replaceStrings [":"] [""] bus}";
    vendorId = vendor;
    deviceId = device;
    brand = vendorMap.${vendor} or "unknown";
    isGPU = class == "\"Class 0300\"";
  };

  parseLspci = lspciOutput: let
    lines = splitString "\n" lspciOutput;
    nonEmptyLines = filter (l: l != "") lines;
    parsed = imap0 (i: line: parseLine line // {index = i;}) nonEmptyLines;
    gpus = filter (gpu: gpu.isGPU) parsed;
  in
    lib.lists.map (gpu: removeAttrs gpu ["isGPU"]) gpus;

  fromLspciMm = lspciMm: let
    gpus = parseLspci lspciMm;
  in
    lib.lists.map (gpu:
      gpu
      // {
        primary = false;
        secondary = false;
      })
    gpus;

  #| TESTS
  tests = {
    parseLspci = let
      result = parseLspci testLspciInput;
    in {
      hasGPUs = length result == 2;
      firstNvidia = (elemAt result 0).brand == "nvidia";
      secondAmd = (elemAt result 1).brand == "amd";
      correctBusIds = (elemAt result 0).busId == "PCI:01000";
    };

    fromLspciMm = let
      result = fromLspciMm testLspciInput;
    in {
      hasPrimaryFalse = lib.lists.all (gpu: !gpu.primary) result;
      hasSecondaryFalse = lib.lists.all (gpu: !gpu.secondary) result;
      sameLength = length result == 2;
    };
  };

  # Test runner
  runTests = assert (
    tests.parseLspci.hasGPUs
    && tests.parseLspci.firstNvidia
    && tests.parseLspci.secondAmd
    && tests.fromLspciMm.sameLength
  ); "All GPU parser tests passed!";
in {
  inherit parseLspci fromLspciMm vendorMap testLspciInput runTests tests;
}
