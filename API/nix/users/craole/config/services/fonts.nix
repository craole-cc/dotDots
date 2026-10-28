{pkgs, ...}: {
  home.packages = with pkgs; [
    maple-mono.NF
    monaspace
  ];
  fonts.fontconfig = {
    enable = true;
    hinting = "slight";
    antialiasing = true;
    subpixelRendering = "rgb";
    defaultFonts = {
      emoji = ["Noto Color Emoji"];
      monospace = [
        "Maple Mono NF"
        "Monaspace Radon"
      ];
      serif = ["Noto Serif"];
      sansSerif = ["Noto Sans"];
    };
  };
}
