{lib, ...}: let
  inherit (lib.attrsets) genAttrs mapAttrs' attrNames;
  inherit (lib.strings) splitString hasPrefix replaceStrings;
  inherit (lib.lists) filter;

  # Vendor ID → brand mapping
  vendorMap = {
    "10de" = "nvidia";
    "1002" = "amd";
    "8086" = "intel";
  };
in {}
