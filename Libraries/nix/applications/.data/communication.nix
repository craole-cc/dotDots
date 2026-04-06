{...}: {
  whatsapp-electron = {
    names = {
      package = "whatsapp-electron";
      command = "whatsapp";
      title = "WhatsApp Electron :: Default Account";
    };
    exec = "whatsapp";
    categories = ["communication" "messenger"];
    family = "whatsapp";
    channel = "stable";
  };

  karere = {
    names = {
      package = "karere";
      command = "karere";
      title = "WhatsApp Electron :: Default Account";
    };
    exec = "karere";
    categories = ["communication" "messenger"];
    family = "whatsapp";
    channel = "stable";
  };

  discord = {
    names = {
      package = "discord";
      command = "discord";
      class = "discord";
    };
    exec = "discord";
    categories = ["communication" "messenger"];
    family = "chromium";
    channel = "stable";
  };

  vesktop = {
    names = {
      package = "vesktop";
      command = "vesktop";
      class = "vesktop";
    };
    exec = "vesktop";
    categories = ["communication"];
    family = "chromium";
    channel = "stable";
  };

  element = {
    names = {
      package = "element-desktop";
      command = "element-desktop";
      class = "Element";
    };
    exec = "element-desktop";
    categories = ["communication" "email-client"];
    family = "chromium";
    channel = "stable";
  };

  fractal = {
    names = {
      package = "fractal";
      command = "fractal";
      class = "org.gnome.Fractal";
    };
    exec = "fractal";
    categories = ["communication" "messenger"];
    channel = "stable";
  };

  telegram = {
    names = {
      package = "telegram-desktop";
      command = "telegram-desktop";
      class = "org.telegram.desktop";
    };
    exec = "telegram-desktop";
    categories = ["communication" "messenger"];
    channel = "stable";
  };

  signal = {
    names = {
      package = "signal-desktop";
      command = "signal-desktop";
      class = "Signal";
    };
    exec = "signal-desktop";
    categories = ["communication" "messenger"];
    family = "chromium";
    channel = "stable";
  };

  thunderbird = {
    names = {
      package = "thunderbird";
      command = "thunderbird";
      class = "thunderbird";
    };
    exec = "thunderbird";
    categories = ["communication" "email-client"];
    family = "firefox";
    channel = "stable";
  };

  evolution = {
    names = {
      package = "gnome.evolution";
      command = "evolution";
      class = "org.gnome.Evolution";
    };
    exec = "evolution";
    categories = ["communication" "email-client"];
    channel = "stable";
  };

  geary = {
    names = {
      package = "geary";
      command = "geary";
      class = "org.gnome.Geary";
    };
    exec = "geary";
    categories = ["communication" "email-client"];
    channel = "stable";
  };
}
