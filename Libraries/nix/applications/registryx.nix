{
  # ── Browsers ─────────────────────────────────────────────────────────────────

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

  zen-twilight = {
    names = {
      package = "zen-browser";
      command = "zen-twilight";
      class = "zen-twilight";
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

  # ── Terminals ────────────────────────────────────────────────────────────────

  foot = {
    names = {
      package = "foot";
      command = "foot";
      class = "foot";
    };
    exec = "foot";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  ghostty = {
    names = {
      package = "ghostty";
      command = "ghostty";
      class = "com.mitchellh.ghostty";
    };
    exec = "ghostty";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  kitty = {
    names = {
      package = "kitty";
      command = "kitty";
      class = "kitty";
    };
    exec = "kitty";
    wrap = {
      titleFlag = "--title";
      execFlag = "--";
    };
    categories = ["terminal"];
  };

  alacritty = {
    names = {
      package = "alacritty";
      command = "alacritty";
      class = "Alacritty";
    };
    exec = "alacritty";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  wezterm = {
    names = {
      package = "wezterm";
      command = "wezterm";
      class = "org.wezfurlong.wezterm";
    };
    exec = "wezterm";
    wrap = {
      titleFlag = "--title";
      execFlag = "start --";
    };
    categories = ["terminal"];
  };

  konsole = {
    names = {
      package = "konsole";
      command = "konsole";
      class = "org.kde.konsole";
    };
    exec = "konsole";
    wrap = {
      titleFlag = "--";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  gnome-terminal = {
    names = {
      package = "gnome-terminal";
      command = "gnome-terminal";
      class = "org.gnome.Terminal";
    };
    exec = "gnome-terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "--";
    };
    categories = ["terminal"];
  };

  xfce4-terminal = {
    names = {
      package = "xfce4-terminal";
      command = "xfce4-terminal";
      class = "xfce4-terminal";
    };
    exec = "xfce4-terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  cosmic-terminal = {
    names = {
      package = "cosmic-term";
      command = "cosmic-term";
      class = "com.system76.CosmicTerm";
    };
    exec = "cosmic-term";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  pantheon-terminal = {
    names = {
      package = "pantheon.elementary-terminal";
      command = "io.elementary.terminal";
      class = "io.elementary.terminal";
    };
    exec = "io.elementary.terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "-x";
    };
    categories = ["terminal"];
  };

  xterm = {
    names = {
      package = "xterm";
      command = "xterm";
      class = "XTerm";
    };
    exec = "xterm";
    wrap = {
      titleFlag = "-T";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  st = {
    names = {
      package = "st";
      command = "st";
      class = "st";
    };
    exec = "st";
    wrap = {
      titleFlag = "-t";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  urxvt = {
    names = {
      package = "rxvt-unicode";
      command = "urxvt";
      class = "URxvt";
    };
    exec = "urxvt";
    wrap = {
      titleFlag = "-title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  tilix = {
    names = {
      package = "tilix";
      command = "tilix";
      class = "com.gexperts.Tilix";
    };
    exec = "tilix";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  # ── Editors ──────────────────────────────────────────────────────────────────

  vscode = {
    names = {
      package = "vscode";
      command = "code";
      class = "code";
    };
    exec = "code";
    categories = ["editor"];
    family = "vscode";
    channel = "stable";
  };

  vscode-insiders = {
    names = {
      package = "vscode-insiders";
      command = "code-insiders";
      class = "code - Insiders";
    };
    exec = "code-insiders";
    categories = ["editor"];
    family = "vscode";
    channel = "insiders";
  };

  vscodium = {
    names = {
      package = "vscodium";
      command = "codium";
      class = "VSCodium";
    };
    exec = "codium";
    categories = ["editor"];
    family = "vscode";
    channel = "stable";
  };

  zed = {
    names = {
      package = "zed-editor";
      command = "zeditor";
      class = "dev.zed.Zed";
    };
    exec = "zeditor";
    categories = ["editor"];
    channel = "stable";
  };

  zed-preview = {
    names = {
      package = "zed-editor";
      command = "zeditor";
      class = "dev.zed.Zed-Preview";
    };
    exec = "zeditor --preview";
    categories = ["editor"];
    channel = "beta";
  };

  emacs = {
    names = {
      package = "emacs";
      command = "emacs";
      class = "Emacs";
    };
    exec = "emacs";
    categories = ["editor" "file-manager"];
    family = "emacs";
    channel = "stable";
  };

  emacs-nox = {
    names = {
      package = "emacs-nox";
      command = "emacs";
      title = "emacs-nox";
    };
    exec = "emacs";
    needsTerminal = true;
    categories = ["editor"];
    family = "emacs";
    channel = "stable";
  };

  helix = {
    names = {
      package = "helix";
      command = "hx";
      title = "helix";
    };
    exec = "hx";
    needsTerminal = true;
    categories = ["editor"];
    channel = "stable";
  };

  neovim = {
    names = {
      package = "neovim";
      command = "nvim";
      title = "nvim";
    };
    exec = "nvim";
    needsTerminal = true;
    categories = ["editor"];
    family = "vim";
    channel = "stable";
  };

  vim = {
    names = {
      package = "vim";
      command = "vim";
      title = "vim";
    };
    exec = "vim";
    needsTerminal = true;
    categories = ["editor"];
    family = "vim";
    channel = "stable";
  };

  nano = {
    names = {
      package = "nano";
      command = "nano";
      title = "nano";
    };
    exec = "nano";
    needsTerminal = true;
    categories = ["editor"];
    channel = "stable";
  };

  kate = {
    names = {
      package = "kate";
      command = "kate";
      class = "org.kde.kate";
    };
    exec = "kate";
    categories = ["editor"];
    channel = "stable";
  };

  gedit = {
    names = {
      package = "gedit";
      command = "gedit";
      class = "org.gnome.gedit";
    };
    exec = "gedit";
    categories = ["editor"];
    channel = "stable";
  };

  mousepad = {
    names = {
      package = "mousepad";
      command = "mousepad";
      class = "org.xfce.mousepad";
    };
    exec = "mousepad";
    categories = ["editor"];
    channel = "stable";
  };

  lite-xl = {
    names = {
      package = "lite-xl";
      command = "lite-xl";
      class = "lite-xl";
    };
    exec = "lite-xl";
    categories = ["editor"];
    channel = "stable";
  };

  lapce = {
    names = {
      package = "lapce";
      command = "lapce";
      class = "dev.lapce.lapce";
    };
    exec = "lapce";
    categories = ["editor"];
    channel = "stable";
  };

  # ── File Managers ─────────────────────────────────────────────────────────────

  yazi = {
    names = {
      package = "yazi";
      command = "yazi";
      title = "yazi";
    };
    exec = "yazi";
    needsTerminal = true;
    categories = ["file-manager"];
  };

  lf = {
    names = {
      package = "lf";
      command = "lf";
      title = "lf";
    };
    exec = "lf";
    needsTerminal = true;
    categories = ["file-manager"];
  };

  ranger = {
    names = {
      package = "ranger";
      command = "ranger";
      title = "ranger";
    };
    exec = "ranger";
    needsTerminal = true;
    categories = ["file-manager"];
  };

  nnn = {
    names = {
      package = "nnn";
      command = "nnn";
      title = "nnn";
    };
    exec = "nnn";
    needsTerminal = true;
    categories = ["file-manager"];
  };

  broot = {
    names = {
      package = "broot";
      command = "broot";
      title = "broot";
    };
    exec = "broot";
    needsTerminal = true;
    categories = ["file-manager"];
  };

  nautilus = {
    names = {
      package = "nautilus";
      command = "nautilus";
      class = "org.gnome.Nautilus";
    };
    exec = "nautilus";
    categories = ["file-manager"];
  };

  dolphin = {
    names = {
      package = "dolphin";
      command = "dolphin";
      class = "org.kde.dolphin";
    };
    exec = "dolphin";
    categories = ["file-manager"];
  };

  thunar = {
    names = {
      package = "xfce.thunar";
      command = "thunar";
      class = "Thunar";
    };
    exec = "thunar";
    categories = ["file-manager"];
  };

  nemo = {
    names = {
      package = "nemo";
      command = "nemo";
      class = "nemo";
    };
    exec = "nemo";
    categories = ["file-manager"];
  };

  pcmanfm = {
    names = {
      package = "pcmanfm";
      command = "pcmanfm";
      class = "Pcmanfm";
    };
    exec = "pcmanfm";
    categories = ["file-manager"];
  };

  doublecmd = {
    names = {
      package = "doublecmd";
      command = "doublecmd";
      class = "doublecmd";
    };
    exec = "doublecmd";
    categories = ["file-manager"];
  };

  krusader = {
    names = {
      package = "krusader";
      command = "krusader";
      class = "org.kde.krusader";
    };
    exec = "krusader";
    categories = ["file-manager"];
  };

  cosmic-files = {
    names = {
      package = "cosmic-files";
      command = "cosmic-files";
      class = "com.system76.CosmicFiles";
    };
    exec = "cosmic-files";
    categories = ["file-manager"];
  };

  pantheon-files = {
    names = {
      package = "pantheon.elementary-files";
      command = "io.elementary.files";
      class = "io.elementary.files";
    };
    exec = "io.elementary.files";
    categories = ["file-manager"];
  };

  spacefm = {
    names = {
      package = "spacefm";
      command = "spacefm";
      class = "spacefm";
    };
    exec = "spacefm";
    categories = ["file-manager"];
  };

  # ── Launchers ────────────────────────────────────────────────────────────────

  vicinae = {
    names = {
      package = "vicinae";
      command = "vicinae";
    };
    exec = "vicinae";
    categories = ["launcher"];
  };

  rofi = {
    names = {
      package = "rofi";
      command = "rofi";
      class = "rofi";
    };
    exec = "rofi -show drun";
    categories = ["launcher"];
  };

  wofi = {
    names = {
      package = "wofi";
      command = "wofi";
      class = "wofi";
    };
    exec = "wofi --show drun";
    categories = ["launcher"];
  };

  fuzzel = {
    names = {
      package = "fuzzel";
      command = "fuzzel";
      class = "fuzzel";
    };
    exec = "fuzzel";
    categories = ["launcher"];
  };

  anyrun = {
    names = {
      package = "anyrun";
      command = "anyrun";
      class = "anyrun";
    };
    exec = "anyrun";
    categories = ["launcher"];
  };

  walker = {
    names = {
      package = "walker";
      command = "walker";
      class = "walker";
    };
    exec = "walker";
    categories = ["launcher"];
  };

  tofi = {
    names = {
      package = "tofi";
      command = "tofi-drun";
      class = "tofi";
    };
    exec = "tofi-drun";
    categories = ["launcher"];
  };

  albert = {
    names = {
      package = "albert";
      command = "albert";
      class = "albert";
    };
    exec = "albert";
    categories = ["launcher"];
  };

  ulauncher = {
    names = {
      package = "ulauncher";
      command = "ulauncher";
      class = "ulauncher";
    };
    exec = "ulauncher";
    categories = ["launcher"];
  };

  krunner = {
    names = {
      package = "krunner";
      command = "krunner";
      class = "krunner";
    };
    exec = "krunner";
    categories = ["launcher"];
  };

  dmenu = {
    names = {
      package = "dmenu";
      command = "dmenu_run";
    };
    exec = "dmenu_run";
    categories = ["launcher"];
  };

  xfce4-appfinder = {
    names = {
      package = "xfce.xfce4-appfinder";
      command = "xfce4-appfinder";
      class = "xfce4-appfinder";
    };
    exec = "xfce4-appfinder";
    categories = ["launcher"];
  };

  # builtin launchers — no exec, managed by the DE/WM itself
  gnome-shell-overview = {
    names = {
      package = "gnome-shell";
      command = "gnome-shell";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  slingshot = {
    names = {
      package = "pantheon.elementary-applications-menu";
      command = "io.elementary.applications-menu";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  cinnamon-menu = {
    names = {
      package = "cinnamon";
      command = "cinnamon";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  cosmic-launcher = {
    names = {
      package = "cosmic-launcher";
      command = "cosmic-launcher";
    };
    exec = "";
    builtin = true;
    categories = ["launcher"];
  };

  # ── Media ────────────────────────────────────────────────────────────────────

  mpv = {
    names = {
      package = "mpv";
      command = "mpv";
      class = "mpv";
    };
    exec = "mpv";
    categories = ["media"];
  };

  vlc = {
    names = {
      package = "vlc";
      command = "vlc";
      class = "vlc";
    };
    exec = "vlc";
    categories = ["media"];
  };

  celluloid = {
    names = {
      package = "celluloid";
      command = "celluloid";
      class = "io.github.celluloid_player.Celluloid";
    };
    exec = "celluloid";
    categories = ["media"];
  };

  totem = {
    names = {
      package = "totem";
      command = "totem";
      class = "org.gnome.Totem";
    };
    exec = "totem";
    categories = ["media"];
  };

  rhythmbox = {
    names = {
      package = "rhythmbox";
      command = "rhythmbox";
      class = "org.gnome.Rhythmbox3";
    };
    exec = "rhythmbox";
    categories = ["media"];
  };

  elisa = {
    names = {
      package = "elisa";
      command = "elisa";
      class = "org.kde.elisa";
    };
    exec = "elisa";
    categories = ["media"];
  };

  strawberry = {
    names = {
      package = "strawberry";
      command = "strawberry";
      class = "org.strawberrymusicplayer.strawberry";
    };
    exec = "strawberry";
    categories = ["media"];
  };

  audacious = {
    names = {
      package = "audacious";
      command = "audacious";
      class = "audacious";
    };
    exec = "audacious";
    categories = ["media"];
  };

  lollypop = {
    names = {
      package = "lollypop";
      command = "lollypop";
      class = "org.gnome.Lollypop";
    };
    exec = "lollypop";
    categories = ["media"];
  };

  shortwave = {
    names = {
      package = "shortwave";
      command = "shortwave";
      class = "de.haeckerfelix.Shortwave";
    };
    exec = "shortwave";
    categories = ["media"];
  };

  # ── Communication ─────────────────────────────────────────────────────────────

  discord = {
    names = {
      package = "discord";
      command = "discord";
      class = "discord";
    };
    exec = "discord";
    categories = ["communication"];
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
    categories = ["communication"];
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
    categories = ["communication"];
    channel = "stable";
  };

  telegram = {
    names = {
      package = "telegram-desktop";
      command = "telegram-desktop";
      class = "org.telegram.desktop";
    };
    exec = "telegram-desktop";
    categories = ["communication"];
    channel = "stable";
  };

  signal = {
    names = {
      package = "signal-desktop";
      command = "signal-desktop";
      class = "Signal";
    };
    exec = "signal-desktop";
    categories = ["communication"];
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
    categories = ["communication"];
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
    categories = ["communication"];
    channel = "stable";
  };

  geary = {
    names = {
      package = "geary";
      command = "geary";
      class = "org.gnome.Geary";
    };
    exec = "geary";
    categories = ["communication"];
    channel = "stable";
  };

  # ── System ───────────────────────────────────────────────────────────────────

  htop = {
    names = {
      package = "htop";
      command = "htop";
      title = "htop";
    };
    exec = "htop";
    needsTerminal = true;
    categories = ["system"];
  };

  btop = {
    names = {
      package = "btop";
      command = "btop";
      title = "btop";
    };
    exec = "btop";
    needsTerminal = true;
    categories = ["system"];
  };

  nvtop = {
    names = {
      package = "nvtop";
      command = "nvtop";
      title = "nvtop";
    };
    exec = "nvtop";
    needsTerminal = true;
    categories = ["system"];
  };

  mission-center = {
    names = {
      package = "mission-center";
      command = "missioncenter";
      class = "io.missioncenter.MissionCenter";
    };
    exec = "missioncenter";
    categories = ["system"];
  };

  gnome-system-monitor = {
    names = {
      package = "gnome.gnome-system-monitor";
      command = "gnome-system-monitor";
      class = "org.gnome.SystemMonitor";
    };
    exec = "gnome-system-monitor";
    categories = ["system"];
  };

  plasma-systemmonitor = {
    names = {
      package = "plasma-systemmonitor";
      command = "plasma-systemmonitor";
      class = "org.kde.plasma-systemmonitor";
    };
    exec = "plasma-systemmonitor";
    categories = ["system"];
  };

  # ── Graphics ─────────────────────────────────────────────────────────────────

  gimp = {
    names = {
      package = "gimp";
      command = "gimp";
      class = "gimp";
    };
    exec = "gimp";
    categories = ["graphics"];
  };

  inkscape = {
    names = {
      package = "inkscape";
      command = "inkscape";
      class = "org.inkscape.Inkscape";
    };
    exec = "inkscape";
    categories = ["graphics"];
  };

  krita = {
    names = {
      package = "krita";
      command = "krita";
      class = "org.kde.krita";
    };
    exec = "krita";
    categories = ["graphics"];
  };

  blender = {
    names = {
      package = "blender";
      command = "blender";
      class = "blender";
    };
    exec = "blender";
    categories = ["graphics"];
  };

  darktable = {
    names = {
      package = "darktable";
      command = "darktable";
      class = "darktable";
    };
    exec = "darktable";
    categories = ["graphics"];
  };

  # ── Office ───────────────────────────────────────────────────────────────────

  libreoffice = {
    names = {
      package = "libreoffice";
      command = "libreoffice";
      class = "libreoffice";
    };
    exec = "libreoffice";
    categories = ["office"];
  };

  libreoffice-writer = {
    names = {
      package = "libreoffice";
      command = "libreoffice";
      class = "libreoffice-writer";
    };
    exec = "libreoffice --writer";
    categories = ["office" "editor"];
  };

  libreoffice-calc = {
    names = {
      package = "libreoffice";
      command = "libreoffice";
      class = "libreoffice-calc";
    };
    exec = "libreoffice --calc";
    categories = ["office"];
  };

  libreoffice-impress = {
    names = {
      package = "libreoffice";
      command = "libreoffice";
      class = "libreoffice-impress";
    };
    exec = "libreoffice --impress";
    categories = ["office"];
  };

  onlyoffice = {
    names = {
      package = "onlyoffice-bin";
      command = "onlyoffice-desktopeditors";
      class = "onlyoffice-desktopeditors";
    };
    exec = "onlyoffice-desktopeditors";
    categories = ["office"];
    family = "chromium";
  };

  obsidian = {
    names = {
      package = "obsidian";
      command = "obsidian";
      class = "obsidian";
    };
    exec = "obsidian";
    categories = ["office" "editor"];
    family = "chromium";
    channel = "stable";
  };

  logseq = {
    names = {
      package = "logseq";
      command = "logseq";
      class = "logseq";
    };
    exec = "logseq";
    categories = ["office" "editor"];
    family = "chromium";
    channel = "stable";
  };

  zathura = {
    names = {
      package = "zathura";
      command = "zathura";
      class = "org.pwmt.zathura";
    };
    exec = "zathura";
    categories = ["office"];
  };

  evince = {
    names = {
      package = "evince";
      command = "evince";
      class = "org.gnome.Evince";
    };
    exec = "evince";
    categories = ["office"];
  };

  okular = {
    names = {
      package = "okular";
      command = "okular";
      class = "org.kde.okular";
    };
    exec = "okular";
    categories = ["office"];
  };
}
