{pkgs, ...}: {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      maple-mono.NF
      monaspace
    ];
    fontconfig = {
      enable = true;
      hinting = {
        enable = false;
        style = "slight";
      };
      antialias = true;
      subpixel.rgba = "rgb";
      defaultFonts = {
        emoji = ["Noto Color Emoji"];
        monospace = ["Maple Mono NF" "Monaspace Radon"];
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
      };
    };
  };
}
