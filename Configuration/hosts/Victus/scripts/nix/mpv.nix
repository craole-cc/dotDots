{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [pkgs.mpv];

  shellHook = ''
    echo "🎶 mpv environment ready — launching mpv.sh automatically"

    # Call the actual shell script with any arguments passed to nix-shell
    /home/craole/Configuration/scripts/shellscript/mpv.sh "$@"

    # Exit after playback ends so nix-shell doesn’t drop you into an interactive shell
    exit
  '';
}
