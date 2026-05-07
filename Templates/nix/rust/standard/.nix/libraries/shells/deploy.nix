{lib, ...}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit
    (lib.strings)
    concatNonEmpty
    concatStringsSep
    escapeShellArg
    mkHeader
    mkSection
    mkStyledOutput
    replaceStrings
    toLines
    ;
  inherit (lib.trivial) readFile;
  inherit (lib.shells) setMarker;

  esc = escapeShellArg;
  anchor = setMarker {};
  project = baseNameOf anchor;

  deployTemplate = name: {
    source,
    target,
  }: let
    targetList = toList target;
    label = esc name;
    path = esc (toString source);
    targets = {
      preferred = esc (head targetList);
      quoted = concatNonEmpty {
        separator = " ";
        parts = map esc targetList;
      };
    };
  in
    with targets; ''
      deploy_entry ${label} ${path} ${preferred} ${quoted} || status=1
    '';

  mkDeployConfig = {
    title ? "Configuration Deployment",
    description ? "Syncing project configuration files into your workspace",
    templates ? {},
    pkgs ? mkPkgs {},
    style ? mkStyledOutput {inherit pkgs;},
  }: let
    content = ''
      ${mkHeader {
        inherit style title;
        content = description;
      }}
      ${mkSection {
        inherit style;
        title = "Entries";
        content = attrNames templates;
      }}
      status=0
      ${toLines (map (n: deployTemplate n templates.${n}) (attrNames templates))}
      return "''${status}"
    '';

    source =
      replaceStrings ["#__DEPLOY_CONF_CALLS__"] [content]
      (readFile ./deploy.sh);
  in
    pkgs.writeShellScriptBin "deploy-config" source;

  deployConfig = {
    pkgs ? mkPkgs {},
    includeAI ? true,
    includeBase ? true,
    includeFormat ? true,
    includeRust ? true,
    includeWeb ? false,
    style ? mkStyledOutput {inherit pkgs;},
    withEditor ? null,
  }: let
    inherit (lib.shells) common;
    inherit (lib.shells) web;
    inherit (lib.shells) editor;
    inherit (lib.shells) rust;
    inherit (lib.shells) ai;

    templates =
      optionalAttrs includeBase (common.base.templates or {})
      // optionalAttrs includeFormat (common.format.templates or {})
      // optionalAttrs includeAI (ai.templates or {})
      // optionalAttrs includeRust (rust.entries.rust or {})
      // optionalAttrs includeWeb (web.templates or {})
      // (
        optionalAttrs
        (withEditor != null && withEditor != "none")
        (editor.entries.common // editor.entries."${withEditor}")
      );
  in
    mkDeployConfig {
      inherit pkgs style templates;
      title = "Configuration Deployment";
      description = "Syncing project configuration files into your workspace";
    };
in {
  inherit mkDeployConfig deployConfig;
}
