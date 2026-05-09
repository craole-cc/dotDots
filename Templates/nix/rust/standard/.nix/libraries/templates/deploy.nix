{lib, ...}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit
    (lib.strings)
    concatNonEmpty
    escapeShellArg
    mkHeader
    mkSection
    mkStyledOutput
    replaceStrings
    toLines
    ;
  inherit (lib.trivial) readFile;

  esc = escapeShellArg;

  mkDeployTemplate = name: {
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
      ${toLines (map (n: mkDeployTemplate n templates.${n}) (attrNames templates))}
      return "''${status}"
    '';

    source =
      replaceStrings ["#__DEPLOY_CONF_CALLS__"] [content]
      (readFile ./deploy.sh);
  in
    pkgs.writeShellScriptBin "deploy-config" source;
in {inherit mkDeployConfig;}
