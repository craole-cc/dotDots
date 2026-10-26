{
  lix,
  cfg,
  pkgs,
  toolkit,
  binaries,
  ...
}: let
  inherit (pkgs) writeShellScript;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (lix.strings.construction) optionalString;
  inherit (lix.lists.construction) optional;
  inherit (toolkit.records) vscode-fhs vscode-insiders;

  #> Correct the resolved Insiders package metadata so desktop/icon/CLI
  #? identity is Insiders rather than stable `code`.
  unwrapped = vscode-insiders.package.overrideAttrs (old: {
    #? Restore the original .NET bundle, as in Nixpkgs' VS Code package.
    postFixup =
      (old.postFixup or "")
      + optionalString isLinux ''
        signer=resources/app/node_modules/@vscode/vsce-sign/bin/vsce-sign
        ${binaries.cp} "./$signer" "$out/lib/vscode/$signer"
        patchelf --add-needed ${pkgs.openssl.out}/lib/libssl.so.3 "$out/lib/vscode/$signer"
        ${binaries.chmod} +x "$out/lib/vscode/$signer"
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
    ${binaries.mkdir} "$root"
    if [ ! -f "$target/resources/app/product.json" ]; then
      temporary="$(${binaries.mktempd} "$root/.prepare.XXXXXX")"
      trap '${binaries.rmf} "$temporary"' EXIT
      ${binaries.cpa} "$source/." "$temporary/"
      ${binaries.chmodr} u+w "$temporary"
      if ! ${binaries.mvt} "$temporary" "$target"; then
        [ -f "$target/resources/app/product.json" ] || exit 1
      fi
      ${binaries.rmf} "$temporary"
      trap - EXIT
    fi
    workbench="$target/resources/app/out/vs/code/electron-browser/workbench"
    appearance="$root/../vscode-wallpaper"
    ${binaries.lnsfn} "$appearance/appearance.json" "$workbench/dotdots-wallpaper.json"
    ${binaries.lnsfn} "$appearance/wallpaper.jpg" "$workbench/dotdots-wallpaper.jpg"
    [ "''${DOTDOTS_VSCODE_PREPARE_ONLY:-0}" = 1 ] && exit 0
    exec "$target/bin/code-insiders" "$@"
  '';
in {
  customPackage = vscode-fhs.package;
  extraPackages = optional cfg.insiders (pkgs.symlinkJoin {
    name = "${unwrapped.name}-writable";
    paths = [unwrapped];
    inherit (unwrapped) meta;
    passthru = (unwrapped.passthru or {}) // {inherit launcher unwrapped;};
    postBuild = ''
      source="${unwrapped}/bin/code-insiders"
      wrapped="${unwrapped}/bin/.code-insiders-wrapped"
      target="$out/bin/code-insiders"
      ${binaries.rmf} "$target"
      ${binaries.cp} "$source" "$target"
      ${binaries.chmod} u+w "$target"
      substituteInPlace "$target" --replace-fail "$wrapped" "${launcher}"
    '';
  });
}
