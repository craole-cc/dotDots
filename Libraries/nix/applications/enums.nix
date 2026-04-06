{_, ...}: let
  __exports = {
    internal = enums;
    external.applicationEnums = __exports.internal;
  };

  inherit (_.lists.construction) mkEnum;
  enums = {
    categories = mkEnum [
      #~@ Common
      "browser"
      "communication"
      "editor"
      "email-client"
      "file-manager"
      "game"
      "graphics"
      "launcher"
      "media"
      "messenger"
      "office"
      "system"
      "terminal"

      #~@ Interface
      "interface"
      "compositor"
      "environment"
      "greeter"
      "notifier"
      "panel"
      "protocol"

      #~@ Shell
      "shell"
      "prompt"
      "line-editor"
      "enhancement"
    ];

    channels = mkEnum {
      values = [
        "stable"
        "beta"
        "nightly"
        "insiders"
        "twilight"
        "esr"
        "legacy"
      ];
      nullable = true;
    };

    families = mkEnum {
      values = [
        "firefox"
        "chromium"
        "zen"
        "vscode"
        "emacs"
        "vim"
        "whatsapp"
      ];
      nullable = true;
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
