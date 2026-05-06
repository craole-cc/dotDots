{lib, ...}: let
  inherit (lib.attrsets) attrNames optionalAttrs;
  inherit (lib.lists) head toList optional;
  inherit (lib.packages) mkPkgs;
  inherit
    (lib.strings)
    concatNonEmpty
    escapeShellArg
    mkHeader
    mkSection
    mkStyledOutput
    replaceStrings
    ;
  inherit (lib.trivial) readFile;
  inherit (lib.shells) rust ai editor setMarker setSource;
  esc = escapeShellArg;

  entries = {
    base = let
      mkSrc = name: setSource ["base" name];
    in {
      envrc = {
        source = mkSrc "envrc";
        target = ".envrc";
      };
      gitignore = {
        source = mkSrc "gitignore";
        target = ".gitignore";
      };
      mise = {
        source = mkSrc "mise";
        target = [".mise.toml" "mise.toml"];
      };
      shellcheck = {
        source = mkSrc "shellcheckrc";
        target = [".shellcheckrc" "shellcheckrc"];
      };
    };

    format = let
      mkSrc = name: setSource ["base" name];
    in {
      markdownlint = {
        source = mkSrc "markdownlint-cli2.yaml";
        target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
      };
      treefmt = {
        source = mkSrc "treefmt.toml";
        target = [".treefmt.toml" "treefmt.toml"];
      };
    };
  };

  deployEntry = name: {
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
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    extraEntries ? {},
    includeFormat ? true,
    title ? "Configuration Deployment",
    description ? "Syncing project configuration files into your workspace",
  }: let
    selected =
      entries.base
      // optionalAttrs includeFormat entries.format
      // extraEntries;

    content = ''
      ${mkHeader {
        inherit print title;
        content = description;
      }}
      ${mkSection {
        inherit print;
        title = "Entries";
        content = attrNames selected;
      }}
      status=0
      ${concatNonEmpty {
        separator = "\n";
        parts = map (n: deployEntry n selected.${n}) (attrNames selected);
      }}
      return "''${status}"
    '';

    source =
      replaceStrings ["#__DEPLOY_CONF_CALLS__"] [content]
      (readFile ./deploy.sh);
  in
    pkgs.writeShellScriptBin "deploy-config" source;

  deployConfig = {
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    extraEntries ? {},
    includeFormat ? true,
    includeRust ? true,
    includeAI ? true,
    withEditor ? null,
    title ? "Configuration Deployment",
    description ? "Syncing project configuration files into your workspace",
  }: let
    selected =
      entries.base
      // optionalAttrs includeFormat entries.format
      // extraEntries;

    delegateCalls = let
      stem = ''/bin/deploy-config'';
      args = ''"$@" || status=1'';
    in
      concatNonEmpty {
        separator = "\n";
        parts =
          optional includeRust ''
            "${rust.deployConfig {
              inherit pkgs print includeFormat;
            }}${stem}" ${args}
          ''
          ++ optional includeAI ''
            "${ai.deployConfig {
              inherit pkgs print includeFormat;
            }}${stem}" ${args}
          ''
          ++ optional (editor != "none") ''
            "${editor.deployConfig {
              inherit pkgs print includeFormat;
              editor = withEditor;
            }}${stem}" ${args}
          '';
      };

    content = ''
      ${mkHeader {
        inherit print title;
        content = description;
      }}
      ${mkSection {
        inherit print;
        title = "Entries";
        content = attrNames selected;
      }}
      status=0
      ${delegateCalls}
      ${concatNonEmpty {
        separator = "\n";
        parts = map (n: deployEntry n selected.${n}) (attrNames selected);
      }}
      return "''${status}"
    '';

    source =
      replaceStrings ["#__DEPLOY_CONF_CALLS__"] [content]
      (readFile ./deploy.sh);
  in
    pkgs.writeShellScriptBin "deploy-config" source;
in {
  inherit entries mkDeployConfig deployConfig;
  anchor = setMarker {};
}
