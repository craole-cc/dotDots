{
  lix,
  cfg,
  pkgs,
  ...
}: let
  inherit (pkgs) writeShellScript;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (lix.strings.construction) optionalString;
  inherit (lix.lists.construction) optional;
  inherit (lix.toolkit.packages) vscode-fhs vscode-insiders;

  #> Correct the resolved Insiders package metadata so desktop/icon/CLI
  #? identity is Insiders rather than stable `code`.
  unwrapped = vscode-insiders.overrideAttrs (old: {
    #? Restore the original .NET bundle, as in Nixpkgs' VS Code package.
    postFixup =
      (old.postFixup or "")
      + optionalString isLinux ''
        signer=resources/app/node_modules/@vscode/vsce-sign/bin/vsce-sign
        ${lix.toolkit.binaries.cp} "./$signer" "$out/lib/vscode/$signer"
        patchelf --add-needed ${pkgs.openssl.out}/lib/libssl.so.3 "$out/lib/vscode/$signer"
        ${lix.toolkit.binaries.chmodx} "$out/lib/vscode/$signer"
      '';
    passthru =
      (old.passthru or {})
      // {
        executableName = "code-insiders";
        longName = "Visual Studio Code - Insiders";
        iconName = "vscode-insiders";
      };
  });

  launcher = writeShellScript "launch-writable-code-insiders" ''
    set -eu
    source=${unwrapped}/lib/vscode
    root="''${XDG_DATA_HOME:-$HOME/.local/share}/dotdots/vscode-insiders"
    package_root=${unwrapped}
    target="$root/''${package_root##*/}"
    ${lix.toolkit.binaries.mkdirp} "$root"
    if [ ! -f "$target/resources/app/product.json" ]; then
      temporary="$(${lix.toolkit.binaries.mktempd} "$root/.prepare.XXXXXX")"
      trap '${lix.toolkit.binaries.rmrf} "$temporary"' EXIT
      ${lix.toolkit.binaries.cpa} "$source/." "$temporary/"
      ${lix.toolkit.binaries.chmodRuw} "$temporary"
      if ! ${lix.toolkit.binaries.mvt} "$temporary" "$target"; then
        [ -f "$target/resources/app/product.json" ] || exit 1
      fi
      ${lix.toolkit.binaries.rmrf} "$temporary"
      trap - EXIT
    fi
    # One writable copy per package revision; older revisions are dead weight.
    # Copies still referenced by a running process are left alone.
    for previous in "$root"/*; do
      [ -d "$previous" ] || continue
      [ "$previous" = "$target" ] && continue
      ${lix.toolkit.binaries.pgrepf} -- "$previous/" >/dev/null 2>&1 && continue
      ${lix.toolkit.binaries.rmrf} "$previous"
    done
    # Nixpkgs patches files in the shipped app after packaging, so the
    # integrity checksums recorded in product.json never match and VS Code
    # claims the installation is corrupt. That list only drives the prompt.
    product="$target/resources/app/product.json"
    if [ -f "$product" ]; then
      ${lix.toolkit.binaries.jaq} '.checksums = {}' "$product" > "$product.dotdots"
      ${lix.toolkit.binaries.mvf} "$product.dotdots" "$product"
    fi
    [ "''${DOTDOTS_VSCODE_PREPARE_ONLY:-0}" = 1 ] && exit 0
    exec "$target/bin/code-insiders" "$@"
  '';
in {
  customPackage = vscode-fhs;
  extraPackages = optional cfg.insiders (pkgs.symlinkJoin {
    name = "${unwrapped.name}-writable";
    paths = [unwrapped];
    inherit (unwrapped) meta;
    passthru = (unwrapped.passthru or {}) // {inherit launcher unwrapped;};
    postBuild = ''
      source="${unwrapped}/bin/code-insiders"
      wrapped="${unwrapped}/bin/.code-insiders-wrapped"
      target="$out/bin/code-insiders"
      ${lix.toolkit.binaries.rmf} "$target"
      ${lix.toolkit.binaries.cp} "$source" "$target"
      ${lix.toolkit.binaries.chmod} u+w "$target"
      substituteInPlace "$target" --replace-fail "$wrapped" "${launcher}"
    '';
  });
}
