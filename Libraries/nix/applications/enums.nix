{_, ...}: let
  __exports = {
    internal = enums.static // enums.derived;
    external.applicationEnums = enums;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) mkEnum;
  inherit (_.types.predicates) isAttrs isEnum;
  inherit (_.applications.filters.queried) shell interface;

  isRegistryAttrset = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

  toEnums = input:
    if isRegistryAttrset input
    then
      mkEnum {
        values = input;
        nullable = true;
      }
    else mapAttrs (_: subtree: toEnums subtree) input;

  enums = {
    static = {
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
        "monitor"
        "office"
        "process"
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

    derived = {
      shells =
        toEnums shell
        // {
          queried =
            toEnums shell.queried
            // {
              system = mkEnum {
                values = shell.queried.system;
                nullable = false;
              };
            };
        };
      interface = toEnums interface;
    };
  };
in
  __exports.internal // {_rootAliases = __exports.external;}
