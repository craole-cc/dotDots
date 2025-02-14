{
  description = "A fully-featured MPV setup with YouTube support and custom scripts";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {nixpkgs}: {
    devShell.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in
      pkgs.mkShell {
        buildInputs = [
          # MPV with YouTube and custom script support
          (pkgs.mpv-unwrapped.override {
            youtubeSupport = true;
            vapoursynthSupport = true; # Optional: for advanced video processing
            ffmpeg_5 = pkgs.ffmpeg-full; # Use full ffmpeg for extended format support
          })
          pkgs.yt-dlp # For downloading/streaming YouTube videos
        ];

        shellHook = ''
          export MPV_HOME=$PWD
          printf "MPV is ready with custom configuration!\n"
        '';
      };
  };
}
