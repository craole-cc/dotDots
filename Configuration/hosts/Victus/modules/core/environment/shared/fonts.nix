{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      #| Monospace
      maple-mono.NF
      monaspace
      victor-mono

      #| System
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
        monospace = ["Maple Mono NF"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
