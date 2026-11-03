{pkgs, ...}: {
  plugins = {
    audioSwitcher.enable = true;
    volumeMixer.enable = true;
    screenRecorder.enable = true;
    dankGifSearch.enable = true;
    dankStickerSearch.enable = true;
  };

  packages = with pkgs; [
    curl
    gpu-screen-recorder
    qt6.qtimageformats
    # kdePackages.qtimageformats
  ];
}
