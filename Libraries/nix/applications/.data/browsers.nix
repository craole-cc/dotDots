{...}: {
  brave = {
    names = {
      package = "brave";
      command = "brave";
      class = "brave-browser";
    };
    exec = "brave";
    categories = ["browser"];
    family = "chromium";
    channel = "stable";
  };

  chromium = {
    names = {
      package = "chromium";
      command = "chromium";
      class = "chromium-browser";
    };
    exec = "chromium";
    categories = ["browser"];
    family = "chromium";
    channel = "stable";
  };

  firefox = {
    names = {
      package = "firefox";
      command = "firefox";
      class = "firefox";
    };
    exec = "firefox";
    categories = ["browser"];
    family = "firefox";
    channel = "stable";
  };

  epiphany = {
    names = {
      package = "epiphany";
      command = "epiphany";
      class = "org.gnome.Epiphany";
    };
    exec = "epiphany";
    categories = ["browser"];
    channel = "stable";
  };

  falkon = {
    names = {
      package = "falkon";
      command = "falkon";
      class = "org.kde.falkon";
    };
    exec = "falkon";
    categories = ["browser"];
    family = "chromium";
    channel = "stable";
  };

  firefox-esr = {
    names = {
      package = "firefox-esr";
      command = "firefox-esr";
      class = "firefox";
    };
    exec = "firefox-esr";
    categories = ["browser"];
    family = "firefox";
    channel = "esr";
  };

  firefox-nightly = {
    names = {
      package = "firefox";
      command = "firefox-nightly";
      class = "firefoxNightly";
    };
    exec = "firefox-nightly";
    categories = ["browser"];
    family = "firefox";
    channel = "nightly";
  };

  librewolf = {
    names = {
      package = "librewolf";
      command = "librewolf";
      class = "LibreWolf";
    };
    exec = "librewolf";
    categories = ["browser"];
    family = "firefox";
    channel = "stable";
  };

  qutebrowser = {
    names = {
      package = "qutebrowser";
      command = "qutebrowser";
      class = "qutebrowser";
    };
    exec = "qutebrowser";
    categories = ["browser"];
    channel = "stable";
  };

  tor-browser = {
    names = {
      package = "tor-browser";
      command = "tor-browser";
      class = "Tor Browser";
    };
    exec = "tor-browser";
    categories = ["browser"];
    channel = "stable";
  };

  vivaldi = {
    names = {
      package = "vivaldi";
      command = "vivaldi";
      class = "vivaldi-stable";
    };
    exec = "vivaldi";
    categories = ["browser"];
    family = "chromium";
    channel = "stable";
  };

  zen-twilight = {
    names = {
      package = "zen-browser";
      command = "zen-twilight";
      class = "zen-twilight";
      title = "Zen Twilight";
    };
    exec = "zen-twilight";
    categories = ["browser"];
    family = "zen";
    channel = "twilight";
  };

  zen-beta = {
    names = {
      package = "zen-browser-beta";
      command = "zen-beta";
      class = "zen-beta";
    };
    exec = "zen-beta";
    categories = ["browser"];
    family = "zen";
    channel = "beta";
  };
}
