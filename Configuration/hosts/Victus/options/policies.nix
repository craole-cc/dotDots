{lib, ...}: let
  inherit (lib.options) mkEnableOption;
in {
  allPolicies = {
    web = mkEnableOption "Basic web access (browser, mail client)";
    webGui = mkEnableOption "Web apps with GUI (web browsers with video)";
    dev = mkEnableOption "Development tooling for TTY (terminal editors, compilers)";
    devGui = mkEnableOption "Development tooling with GUI (IDEs, VSCode)";
    media = mkEnableOption "Media consumption/creation (video, audio, images)";
    webMedia = mkEnableOption "Web-based media (streaming, video conferencing)";
    productivity = mkEnableOption "Productivity applications (office suites, analytics tools)";
    gaming = mkEnableOption "Gaming";
  };
}
