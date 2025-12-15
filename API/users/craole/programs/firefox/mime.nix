{
  lib,
  command,
  ...
}: let
  inherit (lib.attrsets) listToAttrs;

  mimeTypes = [
    "application/x-extension-shtml"
    "application/x-extension-xhtml"
    "application/x-extension-html"
    "application/x-extension-xht"
    "application/x-extension-htm"
    "x-scheme-handler/unknown"
    "x-scheme-handler/mailto"
    "x-scheme-handler/chrome"
    "x-scheme-handler/about"
    "x-scheme-handler/https"
    "x-scheme-handler/http"
    "application/xhtml+xml"
    "application/json"
    "text/plain"
    "text/html"
  ];

  associations = listToAttrs (map (mimeType: {
      name = mimeType;
      value = "${command}.desktop";
    })
    mimeTypes);
in {
  associations.added = associations;
  defaultApplications = associations;
}
