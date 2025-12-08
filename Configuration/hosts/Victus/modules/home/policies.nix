{
  lib,
  hostFunctionalities,
  userCapabilities,
  ...
}: let
  inherit (lib.lists) elem;
  hasFun = f: elem f hostFunctionalities;
  hasCap = c: elem c userCapabilities;

  hasInternet = hasFun "wired" || hasFun "wireless";
  hasGui = hasFun "video";
  hasAudio = hasFun "audio";
in {
  web = hasInternet;
  webGui = hasInternet && hasGui;
  dev = hasCap "development";
  devGui = hasCap "development" && hasGui;
  media = (hasCap "multimedia" || hasCap "creation") && hasAudio && hasGui;
  webMedia = hasInternet && hasAudio && hasGui;
  productivity = (hasCap "writing" || hasCap "analysis" || hasCap "management") && hasGui;
  gaming = hasCap "gaming" && hasGui;
}
