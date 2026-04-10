{_, ...}: let
  __exports = {
    internal = enums;
    external.applicationEnums = enums;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) mkEnum;
  inherit (_.types.predicates) isAttrs;
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
in
  __exports.internal // {_rootAliases = __exports.external;}
