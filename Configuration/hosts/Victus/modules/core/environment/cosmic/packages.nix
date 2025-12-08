{
  pkgs,
  mkIf,
  enable,
  ...
}: {
  config = mkIf enable {
    environment = {
      systemPackages = with pkgs; [
        cosmic-ext-calculator
        cosmic-ext-applet-caffeine
        cosmic-ext-applet-privacy-indicator
        cosmic-ext-applet-external-monitor-brightness
        cosmic-ext-tweaks
        cosmic-reader
        # cosmic-ext-applet-minimon
      ];
      cosmic.excludePackages = with pkgs; [
        cosmic-initial-setup
        # cosmic-term
      ];
    };
  };
}
