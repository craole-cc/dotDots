{lib, ...}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatNonEmpty escapeShellArg replaceStrings toLines;
  inherit (lib.templates) mkCommon mkExtra mkDatabase mkEditor mkRust mkWeb;
  inherit (lib.trivial) readFile;
  arg = escapeShellArg;

  deployTemplates = {
    variant ? {},
    pkgs ? mkPkgs {},
    name ? "deploy-conf",
  }: let
    inherit (variant) common editor extra database rust web;

    templates = (
      {}
      // optionalAttrs common.enable (mkCommon common)
      // optionalAttrs database.enable (mkDatabase database)
      // optionalAttrs editor.enable (mkEditor editor)
      // optionalAttrs extra.enable (mkExtra extra)
      // optionalAttrs rust.enable (mkRust rust)
      // optionalAttrs web.enable (mkWeb web)
    );
  in
    pkgs.writeShellScriptBin name (
      replaceStrings
      ["#__DEPLOY_CONF_CALLS__"]
      [
        ''
          status=0
          ${toLines (
            map
            (n: let
              entry = templates.${n};
              targetList = toList entry.target;
              label = arg n;
              path = arg (toString entry.source);
              preferred = arg (head targetList);
              quoted = concatNonEmpty {
                separator = " ";
                parts = map arg targetList;
              };
            in ''
              deploy_entry ${label} ${path} ${preferred} ${quoted} || status=1
            '')
            (attrNames templates)
          )}
          return "''${status}"
        ''
      ]
      (readFile ./deploy.sh)
    );
in {inherit deployTemplates;}
