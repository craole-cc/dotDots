{
  pkgs,
  package,
}: let
  coreutils = "${pkgs.coreutils}/bin";
  launcher = pkgs.writeShellScript "launch-writable-code-insiders" ''
    set -eu
    source=${package}/lib/vscode
    root="''${XDG_DATA_HOME:-$HOME/.local/share}/dotdots/vscode-insiders"
    package_root=${package}
    target="$root/''${package_root##*/}"
    ${coreutils}/mkdir -p "$root"
    if [ ! -f "$target/resources/app/product.json" ]; then
      temporary="$(${coreutils}/mktemp -d "$root/.prepare.XXXXXX")"
      trap '${coreutils}/rm -rf "$temporary"' EXIT
      ${coreutils}/cp -a --reflink=auto "$source/." "$temporary/"
      ${coreutils}/chmod -R u+w "$temporary"
      if ! ${coreutils}/mv -T "$temporary" "$target"; then
        [ -f "$target/resources/app/product.json" ] || exit 1
      fi
      ${coreutils}/rm -rf "$temporary"
      trap - EXIT
    fi
    workbench="$target/resources/app/out/vs/code/electron-browser/workbench"
    appearance="$root/../vscode-wallpaper"
    ${coreutils}/ln -sfn "$appearance/appearance.json" "$workbench/dotdots-wallpaper.json"
    ${coreutils}/ln -sfn "$appearance/wallpaper.jpg" "$workbench/dotdots-wallpaper.jpg"
    [ "''${DOTDOTS_VSCODE_PREPARE_ONLY:-0}" = 1 ] && exit 0
    exec "$target/bin/code-insiders" "$@"
  '';
in
  pkgs.symlinkJoin {
    name = "${package.name}-writable";
    paths = [package];
    inherit (package) meta;
    passthru =
      (package.passthru or {})
      // {
        inherit launcher;
        unwrapped = package;
      };
    postBuild = ''
      rm "$out/bin/code-insiders"
      cp ${package}/bin/code-insiders "$out/bin/code-insiders"
      chmod u+w "$out/bin/code-insiders"
      substituteInPlace "$out/bin/code-insiders" \
        --replace-fail "${package}/bin/.code-insiders-wrapped" "${launcher}"
    '';
  }
