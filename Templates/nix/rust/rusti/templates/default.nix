{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.strings) concatStringsSep;

  styles = let
    gum = "${pkgs.gum}/bin/gum";
  in {
    error = "${gum} style --foreground 196 --bold --border normal --border-foreground 196 --padding '0 1'";
    success = "${gum} style --foreground 46 --bold";
    warning = "${gum} style --foreground 226 --bold";
    info = "${gum} style --foreground 250";
    code = "${gum} style --foreground 87";
  };

  all = {
    cargo = {
      source = ./cargo-config.toml;
      target = "config/config.toml";
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
      ${styles.error} "❌ ERROR: Template source '${source}' is missing!" >&2
      exit 1
    fi

    mkdir -p "$TARGET_DIR"

    # 2. Deployment check
    if [ ! -f "$FULL_TARGET" ]; then
      ${styles.success} "✨ Deploying missing template to: $FULL_TARGET"
      cp "${source}" "$FULL_TARGET"
      chmod u+w "$FULL_TARGET"
    else
      # 3. Sync check
      if ! cmp -s "${source}" "$FULL_TARGET"; then
        ${styles.warning} "⚠️  WARNING: '$FULL_TARGET' is out of sync with its template." >&2
        ${styles.info} "   -> Action needed: Review changes manually or force sync with:" >&2
        ${styles.code} "      cp ${source} $FULL_TARGET && chmod u+w $FULL_TARGET" >&2
      fi
    fi
  '';

  deployTemplates = templates:
    concatStringsSep "\n" (
      mapAttrsToList (name: config: deployTemplate config) templates
    );
in
  all // {inherit all deployTemplate deployTemplates styles;}
