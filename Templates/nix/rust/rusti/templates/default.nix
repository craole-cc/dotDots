{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) head toList;
  inherit (lib.strings) concatStringsSep mkStyledOutput;

  print = mkStyledOutput {inherit pkgs;};

  entries = {
    cargo = {
      source = ./cargo.toml;
      target = ".cargo/config.toml";
    };
    envrc = {
      source = ./envrc;
      target = ".envrc";
    };
    gitignore = {
      source = ./gitignore;
      target = ".gitignore";
    };
    markdownlint = {
      source = ./markdownlint-cli2.yaml;
      target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
    };
    mise = {
      source = ./mise.toml;
      target = [".mise.toml" "mise.toml"];
    };
    rust-analyzer = {
      source = ./rust-analyzer.toml;
      target = "rust-analyzer.toml";
    };
    rust-toolchain = {
      source = ./rust-toolchain.toml;
      target = "rust-toolchain.toml";
    };
    rustfmt = {
      source = ./rustfmt.toml;
      target = "rustfmt.toml";
    };
    shellcheck = {
      source = ./shellcheckrc;
      target = [".shellcheckrc" "shellcheckrc"];
    };
    treefmt = {
      source = ./treefmt.toml;
      target = [".treefmt.toml" "treefmt.toml"];
    };
  };

  deployTemplate = {
    source,
    target,
  }: let
    target' = let
      targets = toList target;
      toLine = t: "${t}";
      lines = map toLine targets;
      list = concatStringsSep "\n" lines;
      preferred = head targets;
    in {inherit preferred list;};
  in ''
        ROOT="''${PRJ_ROOT:-$PWD}"
        FULL_SOURCE="${source}"
        FULL_PREFERRED="$ROOT/${target'.preferred}"\
        TARGET_LIST="${target'.list}"

        #> Ensure the source exists
        if [ ! -f "$FULL_SOURCE" ]; then
          ${print.error} "Template source $FULL_SOURCE is missing!" >&2
          exit 1
        fi

        #> Ensure target directory exists
        mkdir -p "$(dirname "$FULL_PREFERRED")"

        #> Check if ANY target exists
        EXISTING_TARGET=""
        while IFS= read -r target_line; do
          full_target="$ROOT/$target_line"
          if [ -f "$full_target" ]; then
            EXISTING_TARGET="$full_target"
          fi
        done <<EOF
    $TARGET_LIST
    EOF

    #> Move existing non-preferred to preferred
    if [ -n "$EXISTING_TARGET" ]; then
      case "$EXISTING_TARGET" in
        "$FULL_PREFERRED") ;;
        *)
          ${print.warning} "Moving $EXISTING_TARGET → $FULL_PREFERRED" >&2
          mv "$EXISTING_TARGET" "$FULL_PREFERRED"
          chmod u+w "$FULL_PREFERRED"
          ;;
      esac
    fi

    #> Deploy/update preferred target
    if [ ! -f "$FULL_PREFERRED" ]; then
      ${print.success} "Deploying $FULL_SOURCE → $FULL_PREFERRED" >&2
      cp "$FULL_SOURCE" "$FULL_PREFERRED"
      chmod u+w "$FULL_PREFERRED"
    elif ! cmp -s "$FULL_SOURCE" "$FULL_PREFERRED"; then
      ${print.info} "Updating $FULL_PREFERRED" >&2
      cp "$FULL_SOURCE" "$FULL_PREFERRED"
      chmod u+w "$FULL_PREFERRED"
    else
      ${print.success} "Already up-to-date: $FULL_PREFERRED" >&2
    fi
  '';

  deployTemplates = concatStringsSep "\n" (
    map (t: deployTemplate t) (attrValues entries)
  );
in {inherit entries deployTemplates;}
