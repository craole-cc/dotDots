{lix}: let
  inherit (lix.attrsets.access) attrNames getAttrFromPath;
  inherit (lix.attrsets.aggregation) intersectAttrs mergeSafe;
  inherit (lix.attrsets.construction) optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs mapAttrsToList setAttrByPath;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (lix.types.combinators) attrsOf;
  inherit (lix.types.primitives) anything;

  names = {
    environment = ["environment" "variables"];
    environmentFiles = ["environment" "files"];
    configFile = ["config" "file"];
    hermesHomeFiles = ["home" "file"];
    authFile = ["auth" "file"];
    authFileForceOverwrite = ["auth" "overwrite"];
    extraArgs = ["extra" "args"];
    extraDependencyGroups = ["extra" "dependencyGroups"];
    extraPackages = ["extra" "packages"];
    extraPlugins = ["extra" "plugins"];
    extraPythonPackages = ["extra" "pythonPackages"];
    restart = ["restart" "when"];
    restartSec = ["restart" "seconds"];
  };
  selected = upstream: filterAttrs (name: _path: upstream ? ${name}) names;
  plain = upstream: removeAttrs upstream ((attrNames names) ++ ["backend"]);
  describe = declaration:
    declaration
    // optionalAttrs (declaration ? description) {
      description =
        replaceStrings
        ["environmentFiles" "configFile" "hermesHomeFiles" "authFileForceOverwrite" "authFile" "extraDependencyGroups" "extraPythonPackages" "extraPackages" "extraPlugins" "extraArgs" "restartSec"]
        ["environment.files" "config.file" "home.file" "auth.overwrite" "auth.file" "extra.dependencyGroups" "extra.pythonPackages" "extra.packages" "extra.plugins" "extra.args" "restart.seconds"]
        declaration.description;
    };
in {
  options = upstream:
    mergeSafe (
      [
        (mapAttrs (name: declaration:
          # Upstream deepConfigType merges raw values, leaving nested priority
          # markers untouched. Use a module-aware type for every profile.
            if name == "settings"
            then describe (declaration // {type = attrsOf anything;})
            else if (declaration._type or null) == "option"
            then describe declaration
            else declaration)
        (plain upstream))
      ]
      ++ mapAttrsToList
      (name: path: setAttrByPath path (describe upstream.${name}))
      (selected upstream)
      ++ [
        (optionalAttrs (upstream ? backend) {
          backend =
            (removeAttrs upstream.backend ["extraArgs"])
            // {extra.args = describe upstream.backend.extraArgs;};
        })
      ]
    );

  config = upstream: values:
    (intersectAttrs (plain upstream) values)
    // mapAttrs
    (_name: path: getAttrFromPath path values)
    (selected upstream)
    // optionalAttrs (upstream ? backend) {
      backend =
        (removeAttrs values.backend ["extra"])
        // {extraArgs = values.backend.extra.args;};
    };
}
