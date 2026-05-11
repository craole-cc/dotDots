{lib, ...}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatNonEmpty escapeShellArg replaceStrings toLines;
  inherit (lib.templates) mkBase mkDatabase mkEditor mkRust mkWeb;
  inherit (lib.trivial) readFile;
  arg = escapeShellArg;

  deployTemplates = {
    variant ? {},
    pkgs ? mkPkgs {},
    name ? "deploy-conf",
  }: let
    inherit (variant) base editor database rust web;

    templates =
      {}
      // optionalAttrs (base != null) (mkBase base)
      // optionalAttrs (web != null) (mkWeb web)
      // optionalAttrs (database != null) (mkDatabase database)
      // optionalAttrs (rust != null) (mkRust rust)
      // optionalAttrs (editor != null) (mkEditor editor);
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
