{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  # inherit (lib.lists) filter;
  inherit
    (lib.strings)
    concatStringsSep
    # hasPrefix
    mkStyledOutput
    ;

  print = mkStyledOutput {inherit pkgs;};
  # list = [
  #   ".cargo/config.toml"
  #   ".envrc"
  #   ".gitignore"
  #   ".markdownlint-cli2.yaml"
  #   ".mise.toml"
  #   "mise.toml"
  #   ".treefmt.toml"
  #   "treefmt.toml"
  # ];
  # drop = concatStringsSep " " list;
  # keep = concatStringsSep " " (filter (hasPrefix ".") list);

  all = {
    cargo = {
      source = ./cargo.toml;
      target = ".cargo/config.toml";
    };
    envrc = {
      source = ./.envrc;
      target = ".envrc";
    };
    gitignore = {
      source = ./.gitignore;
      target = ".gitignore";
    };
    markdownlint = {
      source = ./.markdownlint-cli2.yaml;
      target = ".markdownlint-cli2.yaml";
    };
    mise = {
      source = ./mise.toml;
      target = ".mise.toml";
    };
    treefmt = {
      source = ./treefmt.toml;
      target = ".treefmt.toml";
    };
  };

  deployTemplate = {
    source,
    target,
  }: ''
    ROOT="''${PRJ_ROOT:-$PWD}"
    FULL_TARGET="$ROOT/${target}"
    TARGET_DIR=$(dirname "$FULL_TARGET")

    # 1. Source check
    if [ ! -f "${source}" ]; then
      ${print.error} "❌ ERROR: Template source '${source}' is missing!" >&2
      exit 1
    fi

    mkdir -p "$TARGET_DIR"

    # 2. Deployment check
    if [ ! -f "$FULL_TARGET" ]; then
      ${print.success} "✨ Deploying missing template to: $FULL_TARGET"
      cp "${source}" "$FULL_TARGET"
      chmod u+w "$FULL_TARGET"
    else
      # 3. Sync check
      if ! cmp -s "${source}" "$FULL_TARGET"; then
        ${print.warning} "⚠️  WARNING: '$FULL_TARGET' is out of sync with its template." >&2
        ${print.info} "   -> Action needed: Review changes manually or force sync with:" >&2
        ${print.code} " cp ${source} $FULL_TARGET && chmod u+w $FULL_TARGET" >&2
      fi
    fi
  '';

  deployTemplates = templates:
    concatStringsSep "\n" (
      mapAttrsToList
      (_name: deployTemplate)
      templates
    );
in
  all // {inherit all deployTemplate deployTemplates;}
