{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs;
      [
        #~@ Themes
        plasma-overdose-kde-theme
        materia-kde-theme
        arc-kde-theme
        twilight-kde
        adapta-kde-theme
        sweet-nova
        utterly-nord-plasma
        utterly-round-plasma-style

        #~@ Visuals
        kurve
      ]
      ++ (with kdePackages; [
        #~@ Themes
        sierra-breeze-enhanced
        koi

        #~@ Window Management
        krohnkite

        #~@ Applications
        plasmatube
        calindori
        karp

        #~@ Utilities
        kup
        qxlsx
      ]);
    plasma6.excludePackages = with pkgs.kdePackages; [konsole kate];
  };
}
