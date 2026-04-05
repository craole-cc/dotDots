{_, ...}: let
  __exports = {
    internal = enums // {inherit constants;};
    external = {
      applicationEnums = enums;
      applicationConst = constants;
    };
  };

  inherit (_.applications) filters;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) mkEnum;

  constants = {
    categories = mkEnum {
      values = [
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
      ];
      nullable = false;
    };
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

  enums = {
    all = mkEnum filters.all;
    byCategory = mapAttrs (_: v: mkEnum v) filters.byCategory;
    byFamily = mapAttrs (_: v: mkEnum v) filters.byFamily;
    byChannel = mapAttrs (_: v: mkEnum v) filters.byChannel;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
