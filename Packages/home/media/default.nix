{
  lix,
  pkgs,
  ...
}: {
  imports = lix.filesystem.importers.importAll ./.;
  home.packages = with pkgs; [
    gImageReader
    # inkscape
    qbittorrent-enhanced
    # warp-terminal
    # (spacedrive.overrideAttrs (oldAttrs: {
    #   makeWrapperArgs = [
    #     "--set GDK_BACKEND x11"
    #     "--add-flags '--disable-gpu'"
    #     "--add-flags '--disable-gpu-compositing'"
    #   ];
    # }))

    swaybg
  ];
}
