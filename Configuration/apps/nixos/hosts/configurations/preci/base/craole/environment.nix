{ nixosConfig, ... }:
{
  home = {
    inherit (nixosConfig.system) stateVersion;
    # enableNixpkgsReleaseCheck = false;
    extraOutputsToInstall = [
      "doc"
      "devdoc"
    ];
    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code";
      BROWSER = "brave";
      PAGER = "bat --paging=always";
      MANPAGER = "bat --paging=always --plain";
    };
  };
}
