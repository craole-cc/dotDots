## Libraries/nix/applications/.data/browsers.nix

```nix
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

```

## Libraries/nix/applications/.data/communication.nix

```nix
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

```

## Libraries/nix/applications/.data/compositors.nix

```nix
{...}: {
  awesome = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["xorg"];
    role = "standalone";
  };

  bspwm = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["xorg"];
    role = "standalone";
  };

  cosmic-comp = {
    categories = ["compositor" "interface"];
    language = "rust";
    maturity = "young";
    protocol = ["wayland"];
    role = "standalone";
  };

  gala = {
    categories = ["compositor" "interface"];
    language = "vala";
    maturity = "stable";
    protocol = ["xorg"];
    role = "embedded";
  };

  hyprland = {
    categories = ["compositor" "interface"];
    language = "c++";
    maturity = "stable";
    protocol = ["wayland"];
    role = "standalone";
  };

  i3 = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["xorg"];
    role = "standalone";
  };

  kwin = {
    categories = ["compositor" "interface"];
    language = "c++";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    role = "embedded";
  };

  muffin = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["xorg"];
    role = "embedded";
  };

  mutter = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    role = "embedded";
  };

  niri = {
    categories = ["compositor" "interface"];
    language = "rust";
    maturity = "stable";
    protocol = ["wayland"];
    role = "standalone";
  };

  openbox = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "legacy";
    protocol = ["xorg"];
    role = "standalone";
  };

  qtile = {
    categories = ["compositor" "interface"];
    language = "python";
    maturity = "stable";
    protocol = ["xorg"];
    role = "standalone";
  };

  river = {
    categories = ["compositor" "interface"];
    language = "zig";
    maturity = "young";
    protocol = ["wayland"];
    role = "standalone";
  };

  sway = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["wayland"];
    role = "standalone";
  };

  xfwm4 = {
    categories = ["compositor" "interface"];
    language = "c";
    maturity = "stable";
    protocol = ["xorg"];
    role = "embedded";
  };

  xmonad = {
    categories = ["compositor" "interface"];
    language = "haskell";
    maturity = "stable";
    protocol = ["xorg"];
    role = "standalone";
  };
}

```

## Libraries/nix/applications/.data/editors.nix

```nix
{...}: {
  vscode = {
    names = {
      package = "vscode";
      command = "code";
      class = "code";
      title = "Visual Studio Code";
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
}

```

## Libraries/nix/applications/.data/enhancements.nix

```nix
{...}: {
  atuin = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "config.toml";
      home = "$XDG_CONFIG_HOME/atuin";
    };
    shells = ["bash" "zsh" "fish" "nushell"];
    maturity = "stable";
    kind = "history";
  };
  fzf = {
    categories = ["shell" "enhancement"];
    engine = ["go"];
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  mcfly = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "config.toml";
      home = "$XDG_DATA_HOME/mcfly";
    };
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "history";
  };
  skim = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = null;
    shells = ["bash" "zsh" "fish"];
    maturity = "stable";
    kind = "fuzzy";
  };
  zoxide = {
    categories = ["shell" "enhancement"];
    engine = ["rust"];
    config = null;
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh"];
    maturity = "stable";
    kind = "navigation";
  };
}

```

## Libraries/nix/applications/.data/environments.nix

```nix
{...}: {
  #~@ Desktop Environments
  cinnamon = {
    categories = ["environment" "interface"];
    compositor = "muffin";
    greeters = ["lightdm"];
    layouts = ["floating" "stacking"];
    notifier = ["cinnamon"];
    panel = ["cinnamon"];
    protocol = ["xorg"];
    scope = "desktop";
  };

  cosmic = {
    categories = ["environment" "interface"];
    compositor = "cosmic-comp";
    greeters = ["cosmic-greeter" "greetd"];
    layouts = ["floating" "stacking" "tiling"];
    notifier = ["cosmic-notifications"];
    panel = ["cosmic-panel"];
    protocol = ["wayland"];
    scope = "desktop";
  };

  gnome = {
    categories = ["environment" "interface"];
    compositor = "mutter";
    greeters = ["gdm"];
    layouts = ["floating" "stacking" "tiling"];
    notifier = ["gnome-shell"];
    panel = ["gnome-shell"];
    protocol = ["wayland" "xorg"];
    scope = "desktop";
  };

  pantheon = {
    categories = ["environment" "interface"];
    compositor = "gala";
    greeters = ["lightdm"];
    layouts = ["floating" "stacking" "tiling"];
    notifier = ["notification-daemon"];
    panel = ["wingpanel"];
    protocol = ["xorg"];
    scope = "desktop";
  };

  plasma = {
    categories = ["environment" "interface"];
    compositor = "kwin";
    greeters = ["sddm" "plasma-login-shell"];
    layouts = ["floating" "stacking" "tiling"];
    notifier = ["plasmashell"];
    panel = ["plasmashell"];
    protocol = ["wayland" "xorg"];
    scope = "desktop";
  };

  xfce = {
    categories = ["environment" "interface"];
    compositor = "xfwm4";
    greeters = ["lightdm"];
    layouts = ["floating" "stacking"];
    notifier = ["xfce4-notifyd"];
    panel = ["xfce4-panel"];
    protocol = ["xorg"];
    scope = "desktop";
  };

  #~@ Standalone WMs — Wayland
  hyprland = {
    categories = ["environment" "interface"];
    compositor = "hyprland";
    greeters = [
      "regreet"
      "dms-greeter"
      "greetd"
      "tuigreet"
      "ly"
    ];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["mako" "dms-shell" "swaync"];
    panel = [
      "hyprpanel"
      "dms-shell"
      "caelestia"
      "exo"
      "noctalia"
      "waybar"
      "nwg-panel"
      "eww"
    ];
    protocol = ["wayland"];
    scope = "compositor";
  };

  niri = {
    categories = ["environment" "interface"];
    compositor = "niri";
    greeters = ["regreet" "dms-greeter" "greetd" "tuigreet" "ly"];
    layouts = ["tiling" "floating"];
    notifier = ["mako" "dms-shell" "swaync"];
    panel = ["dms-shell" "exo" "noctalia" "waybar" "eww"];
    protocol = ["wayland"];
    scope = "compositor";
  };

  river = {
    categories = ["environment" "interface"];
    compositor = "river";
    greeters = ["regreet" "dms-greeter" "greetd" "tuigreet" "ly"];
    layouts = ["tiling" "floating"];
    notifier = ["mako" "dms-shell" "swaync"];
    panel = ["dms-shell" "waybar" "eww"];
    protocol = ["wayland"];
    scope = "compositor";
  };

  sway = {
    categories = ["environment" "interface"];
    compositor = "sway";
    greeters = ["regreet" "dms-greeter" "greetd" "tuigreet" "ly"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["mako" "dms-shell" "swaync"];
    panel = ["dms-shell" "waybar" "swaybar" "eww"];
    protocol = ["wayland"];
    scope = "compositor";
  };

  #~@ Standalone WMs — Xorg
  awesome = {
    categories = ["environment" "interface"];
    compositor = "awesome";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["dunst"];
    panel = ["awesome" "polybar" "xmobar"];
    protocol = ["xorg"];
    scope = "compositor";
  };

  bspwm = {
    categories = ["environment" "interface"];
    compositor = "bspwm";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["dunst"];
    panel = ["polybar" "lemonbar" "xmobar"];
    protocol = ["xorg"];
    scope = "compositor";
  };

  i3 = {
    categories = ["environment" "interface"];
    compositor = "i3";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["dunst"];
    panel = ["i3bar" "polybar" "lemonbar" "xmobar"];
    protocol = ["xorg"];
    scope = "compositor";
  };

  openbox = {
    categories = ["environment" "interface"];
    compositor = "openbox";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["floating" "stacking"];
    notifier = ["dunst" "xfce4-notifyd"];
    panel = ["tint2" "polybar" "lemonbar"];
    protocol = ["xorg"];
    scope = "compositor";
  };

  qtile = {
    categories = ["environment" "interface"];
    compositor = "qtile";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["dunst"];
    panel = ["qtile" "polybar" "xmobar"];
    protocol = ["xorg"];
    scope = "compositor";
  };

  xmonad = {
    categories = ["environment" "interface"];
    compositor = "xmonad";
    greeters = ["lightdm" "greetd" "regreet"];
    layouts = ["tiling" "floating" "stacking"];
    notifier = ["dunst"];
    panel = ["xmobar" "polybar" "lemonbar"];
    protocol = ["xorg"];
    scope = "compositor";
  };
}

```

## Libraries/nix/applications/.data/file-managers.nix

```nix
{...}: {
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
}

```

## Libraries/nix/applications/.data/graphics.nix

```nix
{...}: {
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
}

```

## Libraries/nix/applications/.data/greeters.nix

```nix
{...}: {
  cosmic-greeter = {
    categories = ["greeter" "interface"];
    kind = "graphical";
    family = "cosmic";
    independent = false;
    engine = ["rust"];
    config = ["ron" "css"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "iced";
  };
  dms-greeter = {
    categories = ["greeter" "interface"];
    family = "dms";
    kind = "graphical";
    independent = true;
    engine = ["rust"];
    config = ["toml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "gtk4";
  };
  gdm = {
    categories = ["greeter" "interface"];
    kind = "graphical";
    family = "gnome";
    independent = false;
    engine = ["c"];
    config = ["javascript" "css"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "gtk4";
  };
  greetd = {
    categories = ["greeter" "interface"];
    family = "greetd";
    kind = "daemon";
    independent = true;
    engine = ["rust"];
    config = ["toml"];
    maturity = "stable";
    protocol = ["wayland" "xorg" "tty" "kms"];
    toolkit = "none";
  };
  lemurs = {
    categories = ["greeter" "interface"];
    kind = "terminal";
    independent = true;
    engine = ["rust"];
    config = ["toml"];
    maturity = "young";
    protocol = ["wayland" "xorg" "tty" "kms"];
    toolkit = "ncurses";
  };
  lightdm = {
    categories = ["greeter" "interface"];
    kind = "graphical";
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "legacy";
    protocol = ["wayland" "xorg"];
    toolkit = "gtk3";
  };
  ly = {
    categories = ["greeter" "interface"];
    kind = "terminal";
    independent = true;
    engine = ["zig"];
    config = ["ini"];
    maturity = "young";
    protocol = ["wayland" "xorg" "tty" "kms"];
    toolkit = "ncurses";
  };
  plasma-login-shell = {
    categories = ["greeter" "interface"];
    family = "plasma";
    kind = "graphical";
    independent = false;
    engine = ["c++" "qml"];
    config = ["qml"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "qt6";
  };
  regreet = {
    categories = ["greeter" "interface"];
    family = "greetd";
    kind = "graphical";
    independent = true;
    engine = ["rust"];
    config = ["toml" "css"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "gtk4";
  };
  sddm = {
    categories = ["greeter" "interface"];
    family = "plasma";
    kind = "graphical";
    independent = true;
    engine = ["c++"];
    config = ["qml" "ini"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "qt6";
  };
  tuigreet = {
    categories = ["greeter" "interface"];
    kind = "terminal";
    independent = true;
    engine = ["rust"];
    config = ["shell"];
    maturity = "stable";
    protocol = ["wayland" "xorg" "tty" "kms"];
    toolkit = "ncurses";
  };
}

```

## Libraries/nix/applications/.data/launchers.nix

```nix
{...}: {
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
}

```

## Libraries/nix/applications/.data/line-editors.nix

```nix
{...}: {
  blesh = {
    categories = ["shell" "line-editor"];
    engine = ["bash"];
    config = {
      lang = ["bash"];
      file = ".blerc";
      home = "$HOME";
    };
    shells = ["bash"];
    maturity = "young";
  };
  readline = {
    categories = ["shell" "line-editor"];
    engine = ["c"];
    config = {
      lang = ["readline"];
      file = ".inputrc";
      home = "$HOME";
    };
    shells = ["bash" "sh" "ksh"];
    maturity = "stable";
  };
  zle = {
    categories = ["shell" "line-editor"];
    engine = ["c" "zsh"];
    shells = ["zsh"];
    maturity = "stable";
  };
}

```

## Libraries/nix/applications/.data/media.nix

```nix
{...}: {
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
}

```

## Libraries/nix/applications/.data/notifiers.nix

```nix
{...}: {
  cinnamon = {
    family = "cinnamon";
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    independent = false;
    engine = ["c"];
    config = ["javascript" "css"];
    maturity = "stable";
  };
  cosmic-notifications = {
    family = "cosmic";
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    independent = false;
    engine = ["rust"];
    config = ["ron" "css"];
    maturity = "young";
  };
  deadd-notification-center = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    independent = true;
    engine = ["haskell"];
    config = ["css"];
    maturity = "young";
  };
  dms-shell = {
    categories = ["interface" "notifier"];
    family = "dms";
    protocol = ["wayland"];
    independent = true;
    engine = ["go"];
    config = ["qml"];
    maturity = "young";
  };
  dunst = {
    categories = ["interface" "notifier"];
    protocol = ["wayland" "xorg"];
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "stable";
  };
  fnott = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "stable";
  };
  gnome-shell = {
    categories = ["interface" "notifier"];
    family = "gnome";
    protocol = ["wayland"];
    independent = false;
    engine = ["c" "javascript"];
    config = ["javascript" "css"];
    maturity = "stable";
  };
  mako = {
    categories = ["interface" "notifier"];
    protocol = ["wayland"];
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "stable";
  };
  notification-daemon = {
    categories = ["interface" "notifier"];
    protocol = ["xorg"];
    independent = false;
    engine = ["c"];
    config = ["ini"];
    maturity = "legacy";
  };
  plasmashell = {
    categories = ["interface" "notifier"];
    family = "plasma";
    protocol = ["wayland"];
    independent = false;
    engine = ["c++" "qml"];
    config = ["qml" "javascript"];
    maturity = "stable";
  };
  xfce4-notifyd = {
    categories = ["interface" "notifier"];
    family = "xfce";
    protocol = ["xorg"];
    independent = false;
    engine = ["c"];
    config = ["rc" "css"];
    maturity = "stable";
  };
}

```

## Libraries/nix/applications/.data/office.nix

```nix
{...}: {
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

```

## Libraries/nix/applications/.data/panels.nix

```nix
{...}: {
  awesome = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c" "lua"];
    config = ["lua"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "cairo";
  };

  caelestia = {
    # family = "caelestia";
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++" "qml"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  cinnamon = {
    categories = ["panel" "interface"];
    family = "cinnamon";
    independent = false;
    engine = ["c"];
    config = ["javascript" "css"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "gtk3";
  };

  cosmic-panel = {
    categories = ["panel" "interface"];
    family = "cosmic";
    independent = false;
    engine = ["rust"];
    config = ["ron" "css"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "iced";
  };

  dms-shell = {
    categories = ["panel" "interface"];
    family = "dms";
    independent = true;
    engine = ["go"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  eww = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["rust"];
    config = ["yuck" "scss"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "gtk3";
  };

  exo = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["python"];
    config = ["python" "scss"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "gtk4";
  };

  gnome-shell = {
    categories = ["panel" "interface"];
    family = "gnome";
    independent = false;
    engine = ["c" "javascript"];
    config = ["javascript" "css"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "st";
  };

  i3bar = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["json" "shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xcb";
  };

  hyprpanel = {
    categories = ["panel" "interface"];
    family = "hyprland";
    independent = true;
    engine = ["typescript"];
    config = ["typescript" "scss"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  lemonbar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c"];
    config = ["shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xcb";
  };

  noctalia = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["qml"];
    maturity = "young";
    protocol = ["wayland"];
    toolkit = "qt6";
  };

  nwg-panel = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["python"];
    config = ["json" "css"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  plasmashell = {
    categories = ["panel" "interface"];
    family = "plasma";
    independent = false;
    engine = ["c++" "qml"];
    config = ["qml" "javascript"];
    maturity = "stable";
    protocol = ["wayland" "xorg"];
    toolkit = "qt6";
  };

  polybar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["ini" "shell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "cairo";
  };

  qtile = {
    categories = ["panel" "interface"];
    independent = false;
    engine = ["python" "c"];
    config = ["python"];
    maturity = "stable";
    protocol = ["xorg" "wayland"];
    toolkit = "cairo";
  };

  swaybar = {
    categories = ["panel" "interface"];
    family = "sway";
    independent = false;
    engine = ["c"];
    config = ["shell" "json"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "cairo";
  };

  tint2 = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c"];
    config = ["ini"];
    maturity = "legacy";
    protocol = ["xorg"];
    toolkit = "pango";
  };

  waybar = {
    categories = ["panel" "interface"];
    independent = true;
    engine = ["c++"];
    config = ["jsonc" "css"];
    maturity = "stable";
    protocol = ["wayland"];
    toolkit = "gtk3";
  };

  wingpanel = {
    categories = ["panel" "interface"];
    family = "pantheon";
    independent = false;
    engine = ["vala" "c"];
    config = ["css"];
    maturity = "stable";
    protocol = ["xorg" "wayland"];
    toolkit = "gtk3";
  };

  xfce4-panel = {
    family = "xfce";
    categories = ["panel" "interface"];
    independent = false;
    engine = ["c"];
    config = ["rc" "css"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "gtk3";
  };

  xmobar = {
    family = "xmonad";
    categories = ["panel" "interface"];
    independent = true;
    engine = ["haskell"];
    config = ["haskell"];
    maturity = "stable";
    protocol = ["xorg"];
    toolkit = "xft";
  };
}

```

## Libraries/nix/applications/.data/prompts.nix

```nix
{...}: {
  hydro = {
    categories = ["shell" "prompt"];
    engine = ["fish"];
    shells = ["fish"];
    maturity = "stable";
  };
  liquidprompt = {
    categories = ["shell" "prompt"];
    engine = ["bash"];
    config = {
      lang = ["bash"];
      file = ".liquidpromptrc";
      home = "$HOME";
    };
    shells = ["bash" "zsh"];
    maturity = "stable";
  };
  oh-my-nu = {
    categories = ["shell" "prompt"];
    engine = ["nu"];
    shells = ["nushell"];
    maturity = "young";
  };
  ohmyposh = {
    categories = ["shell" "prompt"];
    engine = ["go"];
    config = {
      lang = ["toml"];
      file = "zen.toml";
      home = "$XDG_CONFIG_HOME/ohmyposh";
    };
    shells = ["bash" "zsh" "fish" "nushell" "pwsh"];
    maturity = "stable";
  };
  powerlevel10k = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = ".p10k.zsh";
      home = "$HOME";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  powerline = {
    categories = ["shell" "prompt"];
    engine = ["python"];
    config = {
      lang = ["json"];
      file = "config.json";
      home = "$XDG_CONFIG_HOME/powerline";
    };
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "legacy";
  };
  powerline-go = {
    categories = ["shell" "prompt"];
    engine = ["go"];
    shells = ["bash" "zsh" "fish" "pwsh"];
    maturity = "stable";
  };
  powerline-rs = {
    categories = ["shell" "prompt"];
    engine = ["rust"];
    shells = ["bash" "zsh" "fish"];
    maturity = "young";
  };
  prezto = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = ".zpreztorc";
      home = "$HOME";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  pure = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    shells = ["zsh"];
    maturity = "stable";
  };
  spaceship = {
    categories = ["shell" "prompt"];
    engine = ["zsh"];
    config = {
      lang = ["zsh"];
      file = "spaceship.zsh";
      home = "$XDG_CONFIG_HOME/spaceship";
    };
    shells = ["zsh"];
    maturity = "stable";
  };
  starship = {
    categories = ["shell" "prompt"];
    engine = ["rust"];
    config = {
      lang = ["toml"];
      file = "starship.toml";
      home = "$XDG_CONFIG_HOME";
    };
    shells = ["bash" "zsh" "fish" "nushell" "elvish" "pwsh" "tcsh"];
    maturity = "stable";
  };
  tide = {
    categories = ["shell" "prompt"];
    engine = ["fish"];
    shells = ["fish"];
    maturity = "stable";
  };
}

```

## Libraries/nix/applications/.data/protocols.nix

```nix
{...}: {
  tty = {
    categories = ["interface" "protocol"];
    surface = "console";
    acceleration = false;
    compositing = false;
    remote = false;
    maturity = "legacy";
  };
  kms = {
    categories = ["interface" "protocol"];
    surface = "native";
    acceleration = true;
    compositing = false;
    remote = false;
    maturity = "stable";
  };
  wayland = {
    categories = ["interface" "protocol"];
    surface = "native";
    acceleration = true;
    compositing = true;
    remote = true;
    maturity = "stable";
  };
  xorg = {
    categories = ["interface" "protocol"];
    surface = "native";
    acceleration = true;
    compositing = true;
    remote = true;
    maturity = "legacy";
  };
}

```

## Libraries/nix/applications/.data/shells.nix

```nix
{...}: {
  bash = {
    categories = ["shell"];
    config = {
      lang = ["bash"];
      file = ".bashrc";
      home = "$HOME";
    };
    engine = ["c"];
    interactive = true;
    posix = true;
    system = true;
    maturity = "stable";
  };
  dash = {
    categories = ["shell"];
    config = {
      lang = ["sh"];
      file = ".profile";
      home = "$HOME";
    };
    engine = ["c"];
    interactive = true;
    maturity = "stable";
    posix = true;
    system = true;
  };
  elvish = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    engine = ["go"];
    config = {
      lang = ["elvish"];
      file = "rc.elv";
      home = "$XDG_CONFIG_HOME/elvish";
    };
    maturity = "young";
  };
  fish = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    engine = ["rust"];
    config = {
      lang = ["fish"];
      file = "config.fish";
      home = "$XDG_CONFIG_HOME/fish";
    };
    maturity = "stable";
  };
  ksh = {
    categories = ["shell"];
    posix = true;
    interactive = true;
    system = true;
    engine = ["c"];
    config = {
      lang = ["ksh"];
      file = ".kshrc";
      home = "$HOME";
    };
    maturity = "stable";
  };
  nushell = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    engine = ["rust"];
    config = {
      lang = ["nu"];
      file = "config.nu";
      home = "$XDG_CONFIG_HOME/nushell";
    };
    maturity = "young";
  };
  pwsh = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    engine = ["dotnet" "csharp"];
    config = {
      lang = ["powershell"];
      file = "profile.ps1";
      home = "$XDG_CONFIG_HOME/powershell";
    };
    maturity = "stable";
  };
  sh = {
    categories = ["shell"];
    posix = true;
    interactive = false;
    system = true;
    engine = ["c"];
    config = {
      lang = ["sh"];
      file = ".profile";
      home = "$HOME";
    };
    maturity = "legacy";
  };
  tcsh = {
    categories = ["shell"];
    posix = false;
    interactive = true;
    system = false;
    engine = ["c"];
    config = {
      lang = ["csh"];
      file = ".tcshrc";
      home = "$HOME";
    };
    maturity = "legacy";
  };
  zsh = {
    categories = ["shell"];
    posix = true;
    interactive = true;
    system = true;
    engine = ["c"];
    config = {
      lang = ["zsh"];
      file = ".zshrc";
      home = "$HOME";
    };
    maturity = "stable";
  };
}

```

## Libraries/nix/applications/.data/sysmon.nix

```nix
{...}: {
  htop = {
    names = {
      package = "htop";
      command = "htop";
      title = "htop";
    };
    exec = "htop";
    needsTerminal = true;
    categories = ["monitor" "process" "system"];
  };

  btop = {
    names = {
      package = "btop";
      command = "btop";
      title = "btop";
    };
    exec = "btop";
    needsTerminal = true;
    categories = ["monitor" "process" "system"];
  };

  nvtop = {
    names = {
      package = "nvtop";
      command = "nvtop";
      title = "nvtop";
    };
    exec = "nvtop";
    needsTerminal = true;
    categories = ["monitor" "process" "system"];
  };

  mission-center = {
    names = {
      package = "mission-center";
      command = "missioncenter";
      class = "io.missioncenter.MissionCenter";
    };
    exec = "missioncenter";
    categories = ["monitor" "process" "system"];
  };

  gnome-system-monitor = {
    family = "gnome";
    names = {
      package = "gnome.gnome-system-monitor";
      command = "gnome-system-monitor";
      class = "org.gnome.SystemMonitor";
    };
    exec = "gnome-system-monitor";
    categories = ["monitor" "process" "system"];
  };

  plasma-systemmonitor = {
    family = "plasma";
    names = {
      package = "plasma-systemmonitor";
      command = "plasma-systemmonitor";
      class = "org.kde.plasma-systemmonitor";
    };
    exec = "plasma-systemmonitor";
    categories = ["monitor" "process" "system"];
  };
}

```

## Libraries/nix/applications/.data/terminals.nix

```nix
{...}: {
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
    protocol = ["wayland"];
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
    family = "plasma";
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
    family = "gnome";
    categories = ["terminal"];
  };

  xfce4-terminal = {
    names = {
      package = "xfce4-terminal";
      command = "xfce4-terminal";
      class = "xfce4-terminal";
    };
    family = "xfce";
    exec = "xfce4-terminal";
    wrap = {
      titleFlag = "--title";
      execFlag = "-e";
    };
    categories = ["terminal"];
  };

  cosmic-terminal = {
    family = "cosmic";
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
    family = "pantheon";
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
    protocol = ["xorg"];
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
    protocol = ["xorg"];
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
    protocol = ["xorg"];
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
}

```

## Libraries/nix/applications/filters.nix

```nix
{_, ...}: let
  __exports = {
    internal = filters;
    external.applicationFilters = filters;
  };

  inherit (_.applications.construction) mkFilters;
  inherit (_.attrsets.access) attrByPath attrNames attrValues;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.predicates) isAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.lists.access) length;
  inherit (_.lists.predicates) isIn isList;
  inherit (_.lists.reduction) concatMap;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) splitString toPascal;
  all = _.applications.registry;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Primitives                                                ║
  #╚═══════════════════════════════════════════════════════════╝

  toPath = field:
    if isList field
    then field
    else splitString "." field;

  toValue = {
    field,
    default ? null,
  }: app:
    attrByPath (toPath field) default app;

  toName = {
    prefix ? "by",
    field,
    suffix ? "",
  }: let
    normalized = concatStringsSep "-" (toPath field);
    name = toPascal normalized;
  in
    prefix + name + suffix;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Predicates                                                ║
  #╚═══════════════════════════════════════════════════════════╝
  hasField = {
    field,
    set,
  }:
    filter
    (a: toValue {inherit field;} a != null) (attrValues set)
    != [];

  hasListField = {
    field,
    set,
  }:
    filter
    (a: isList (toValue {inherit field;} a)) (attrValues set)
    != [];

  #╔═══════════════════════════════════════════════════════════╗
  #║ Primitive Filters                                         ║
  #╚═══════════════════════════════════════════════════════════╝
  withFlag = {
    field,
    set,
  }:
    filterAttrs (_:
      toValue {
        inherit field;
        default = false;
      })
    set;

  withoutFlag = {
    field,
    set,
  }:
    filterAttrs (_: a:
      !(toValue {
          inherit field;
          default = false;
        }
        a))
    set;

  withNeq = {
    field,
    default ? null,
    value ? null,
    set,
  }:
    filterAttrs (_: a:
      toValue {
        inherit field;
        inherit default;
      }
      a
      != value)
    set;

  normalizeConfig = {
    set,
    path ? ["config"],
  }:
    mapAttrs (
      _: a: let
        cfg = attrByPath path null a;
      in
        if cfg != null && cfg.home != null && cfg.file != null
        then
          recursiveUpdate a (
            setAttrByPath path (
              cfg // {path = "${cfg.home}/${cfg.file}";}
            )
          )
        else a
    )
    set;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Field Query Builders                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  mkEqQueries = {
    field,
    set,
  }: let
    getVal = toValue {inherit field;};
    keys = unique (filter (v: v != null) (map getVal (attrValues set)));
  in
    genAttrs keys (
      value:
        filterAttrs (_: a: getVal a == value) set
    );

  mkMemberQueries = {
    field,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
    keys = unique (concatMap getVal (attrValues set));
  in
    genAttrs keys (
      value:
        filterAttrs (_: a: isIn value (getVal a)) set
    );

  mkBoolQueries = {
    field,
    trueKey,
    falseKey,
    set,
  }: {
    ${trueKey} = withFlag {inherit field set;};
    ${falseKey} = withoutFlag {inherit field set;};
  };

  mkLengthQueries = {
    field,
    singleKey,
    multiKey,
    set,
  }: let
    getVal = toValue {
      inherit field;
      default = [];
    };
  in {
    ${singleKey} = filterAttrs (_: a: length (getVal a) == 1) set;
    ${multiKey} = filterAttrs (_: a: length (getVal a) > 1) set;
  };

  mkLengthQueriesFor = {
    set,
    field,
  }:
    optionalAttrs (field != null)
    (
      optionalAttrs (hasListField {inherit field set;}) (
        mkLengthQueries {
          inherit set field;
          singleKey = "single" + toPascal field;
          multiKey = "multi" + toPascal field;
        }
      )
    );

  mkNamedQueries = {
    prefix,
    set,
    suffix ? "",
  }:
    listToAttrs (
      map (field: {
        name = toName {inherit prefix suffix field;};
        value = set.${field};
      }) (attrNames set)
    );

  #╔═══════════════════════════════════════════════════════════╗
  #║ Semantic Helpers                                          ║
  #╚═══════════════════════════════════════════════════════════╝
  mkMaturityGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "maturity";
    };

  mkMaturityQueries = {set}:
    mkNamedQueries {
      prefix = "is";
      set = mkMaturityGroup {inherit set;};
    };

  mkProtocolGroup = {set}:
    mkMemberQueries {
      inherit set;
      field = "protocol";
    };

  mkProtocolQueries = {set}:
    mkNamedQueries {
      prefix = "for";
      set = mkProtocolGroup {inherit set;};
    };

  mkCapabilityGroup = {set}: let
    fields = ["acceleration" "compositing" "remote" "floating"];
  in
    filterAttrs (_: v: v != {}) (
      genAttrs fields (field: withFlag {inherit field set;})
    );

  mkCapabilityQueries = {set}:
    mkNamedQueries {
      prefix = "has";
      set = mkCapabilityGroup {inherit set;};
    };

  mkScopeGroup = {set}:
    mkEqQueries {
      inherit set;
      field = "scope";
    };
  mkScopeQueries = {set}:
    mkNamedQueries {
      prefix = "as";
      set = mkScopeGroup {inherit set;};
    };

  mkIndependenceQueries = {set}: let
    field = "independent";
  in
    optionalAttrs (hasField {inherit field set;}) (
      mkBoolQueries {
        inherit field set;
        trueKey = field;
        falseKey = "integrated";
      }
    );

  mkConfigQueries = {set}: let
    withConfig =
      filterAttrs
      (_: a: let
        cfg = toValue {field = "config";} a;
      in
        isAttrs cfg && cfg ? file)
      set;

    profileOnly =
      filterAttrs
      (_: a: toValue {field = "config.file";} a == ".profile")
      withConfig;

    isConfigurable = removeAttrs withConfig (attrNames profileOnly);
  in
    optionalAttrs (withConfig != {})
    {inherit isConfigurable;};

  mkStandardQueries = {
    set,
    field ? null,
  }:
    {}
    // mkCapabilityQueries {inherit set;}
    // mkConfigQueries {inherit set;}
    // mkIndependenceQueries {inherit set;}
    // mkMaturityQueries {inherit set;}
    // mkProtocolQueries {inherit set;}
    // mkScopeQueries {inherit set;}
    // mkLengthQueriesFor {inherit set field;}
    // {};

  #╔═══════════════════════════════════════════════════════════╗
  #║ Group Helpers                                             ║
  #╚═══════════════════════════════════════════════════════════╝
  mkConfigFileGroup = {set}: let
    getVal = toValue {field = "config.file";};
    withCfg =
      filterAttrs
      (_: a: toValue {field = "config";} a != null)
      set;
    keys = unique (
      filter
      (v: v != null)
      (map getVal (attrValues withCfg))
    );
  in
    genAttrs keys (
      file: filterAttrs (_: a: getVal a == file) set
    );

  mkStandardGrouped = {
    set,
    eq ? [],
    member ? [],
    fields ? [],
  }: let
    perField = {
      maturity = mkMaturityGroup {inherit set;};
      protocol = mkProtocolGroup {inherit set;};
      config = mkConfigFileGroup {inherit set;};
      capability = mkCapabilityGroup {inherit set;};
    };
    allFields = unique (eq ++ member ++ fields);
  in
    listToAttrs (
      map (field: {
        name = toName {inherit field;};
        value =
          perField.${
            field
          } or (
            if isIn field eq
            then mkEqQueries {inherit set field;}
            else mkMemberQueries {inherit set field;}
          );
      })
      allFields
    );

  #╔═══════════════════════════════════════════════════════════╗
  #║ Core                                                      ║
  #╚═══════════════════════════════════════════════════════════╝
  filters = mkFilters {
    inherit all;
    queries = {byCategory, ...}: let
      needsTerminal = withFlag {
        field = "needsTerminal";
        set = all;
      };

      shell = let
        all = byCategory.shell;
      in {
        inherit all;

        shells = let
          all = normalizeConfig {
            set = filterAttrs (_: a: (a.categories or []) == ["shell"]) byCategory.shell;
          };
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            member = ["engine"];
            fields = ["config" "maturity"];
          };
          queries =
            mkStandardQueries {
              inherit set;
              field = "shells";
            }
            // mkBoolQueries {
              inherit set;
              field = "posix";
              trueKey = "posix";
              falseKey = "modern";
            };
        in {inherit all groups queries;};

        prompts = let
          all = byCategory.prompt;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["engine"];
            member = ["shells"];
            fields = ["maturity"];
          };
          queries = mkStandardQueries {
            inherit set;
            field = "shells";
          };
        in {inherit all groups queries;};

        enhancements = let
          all = byCategory.enhancement;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["kind"];
            member = ["shells" "engine"];
            fields = ["maturity"];
          };
          queries =
            {inherit (groups.byKind) history fuzzy navigation;}
            // mkStandardQueries {
              inherit set;
              field = "shells";
            };
        in {inherit all groups queries;};

        lineEditors = let
          all = byCategory."line-editor";
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            member = ["engine" "shell"];
            fields = ["maturity"];
          };
          queries = mkStandardQueries {
            inherit set;
            field = "shells";
          };
        in {inherit all groups queries;};
      };

      interface = let
        all = byCategory.interface;
        set = all;
        compositors = let
          all = byCategory.compositor;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["role"];
            fields = ["protocol" "maturity"];
          };
          queries = mkStandardQueries {inherit set;};
        in {inherit all groups queries;};

        environments = let
          all = byCategory.environment;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["compositor" "scope"];
            member = ["panel" "layouts" "greeters"];
            fields = ["protocol" "maturity"];
          };
          queries =
            {inherit (groups.byLayouts) tiling floating stacking;}
            // groups.byScope
            // mkStandardQueries {inherit set;};
        in {inherit all groups queries;};

        greeters = let
          all = byCategory.greeter;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["kind" "toolkit"];
            fields = ["protocol"];
          };
          queries =
            mkStandardQueries {inherit set;}
            // groups.byToolkit
            // groups.byKind;
        in {inherit all groups queries;};

        notifiers = let
          all = byCategory.notifier;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            member = ["config.lang"];
            fields = ["maturity" "protocol"];
          };
          queries = mkStandardQueries {inherit set;};
        in {inherit all groups queries;};

        panels = let
          all = byCategory.panel;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["toolkit"];
            member = ["config.lang" "engine"];
            fields = ["maturity" "protocol"];
          };
          queries = mkStandardQueries {
            inherit set;
            field = "toolkit";
          };
        in {inherit all groups queries;};

        protocols = let
          all = byCategory.protocol;
          set = all;
          groups = mkStandardGrouped {
            inherit set;
            eq = ["surface"];
            fields = ["capability" "maturity"];
          };
          queries =
            mkStandardQueries {inherit set;}
            // mkCapabilityQueries {inherit set;}
            // groups.bySurface;
        in {inherit all groups queries;};
      in {inherit all compositors environments greeters notifiers panels protocols;};
    in {inherit needsTerminal shell interface;};
  };
in
  __exports.internal // {_rootAliases = __exports.external;}

```

## Libraries/nix/applications/registry.nix

```nix
{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  inherit (_.applications.construction) importRegistry;

  all = importRegistry ./.data;
in
  __exports.internal // {_rootAliases = __exports.external;}

```

## Libraries/nix/applications/enums.nix

```nix
{_, ...}: let
  __exports = {
    internal = enums;
    external.applicationEnums = enums;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) mkEnum;
  inherit (_.types.predicates) isAttrs;
  inherit (_.applications.filters.queried) shell interface;

  isRegistryAttrset = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

  toEnums = input:
    if isRegistryAttrset input
    then
      mkEnum {
        values = input;
        nullable = true;
      }
    else mapAttrs (_: subtree: toEnums subtree) input;

  enums = {
    shells =
      toEnums shell
      // {
        queried =
          toEnums shell.queried
          // {
            system = mkEnum {
              values = shell.queried.system;
              nullable = false;
            };
          };
      };
    interface = toEnums interface;
  };
in
  __exports.internal // {_rootAliases = __exports.external;}

```

## Libraries/nix/applications/construction.nix

```nix
{_, ...}: let
  exports = {
    internal = {
      inherit
        mkFilters
        mkRegistry
        importRegistry
        mkShellApp
        mkScriptWrapper
        mkScriptWrappers
        mkSubsystem
        ;
    };
    external = exports.internal;
  };

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs mapAttrsToList;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.filesystem.access) readFile;
  inherit (_.filesystem.importers) importAllMerged;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) unique;
  inherit (_.strings.transformation) escapeShellArgs;
  inherit (_.types.predicates) isList isPath isString;

  normalizeOptional = value:
    if value == null || value == "" || value == "none"
    then null
    else value;

  normalizeList = values:
    if isList values
    then filter (value: value != null && value != "" && value != "none") values
    else [];

  keysFromOptional = field: set:
    unique (
      filter (value: value != null) (
        map (item: normalizeOptional (item.${field} or null)) (attrValues set)
      )
    );

  keysFromMembers = field: set:
    unique (
      builtins.concatMap (item: normalizeList (item.${field} or [])) (attrValues set)
    );

  mkRegistry = data:
    mapAttrs (_: app:
      app
      // {
        categories = normalizeList (app.categories or []);
        channel = normalizeOptional (app.channel or null);
        family = normalizeOptional (app.family or null);
      })
    data;

  importRegistry = path:
    mkRegistry (importAllMerged path {});

  mkFilters = {
    all,
    groups ? {},
    queries ? (_: {}),
  }: let
    byCategory = genAttrs (keysFromMembers "categories" all) (
      category:
        filterAttrs (_: app: isIn category (app.categories or [])) all
    );

    byFamily = genAttrs (keysFromOptional "family" all) (
      family:
        filterAttrs (_: app: (app.family or null) == family) all
    );

    byChannel = genAttrs (keysFromOptional "channel" all) (
      channel:
        filterAttrs (_: app: (app.channel or null) == channel) all
    );

    ofCategory = category:
      byCategory.${category} or {};
  in {
    inherit all;
    groups =
      {
        inherit byCategory byFamily byChannel ofCategory;
      }
      // groups;
    queries = queries {inherit byCategory byFamily byChannel;};
  };

  mkSubsystem = {
    path,
    groups ? {},
    queries ? (_: {}),
  }: let
    all = importRegistry path;
  in {
    inherit all;
    registry = all;
    filters = mkFilters {
      inherit all groups queries;
    };
  };

  /**
    mkShellApp - A helper function to create a shell script application with runtime dependencies
    and optional aliases.

    # Arguments
    - name (string):            The name of the application
    - inputs (list, optional):  List of packages to include in the runtime PATH (default: [])
    - command (string):         The shell script content to execute
    - prefix (string, optional): Prefix to add to command and alias names (default: "")
    - aliases (list, optional): List of alias specifications {name, description, prefix?}
    - description (string, optional): Description of the command for help text

    # Returns
    An attrset containing the main application and all its aliases

    # Example
  \```nix
    mkShellApp {
      name = "dots";
      prefix = ".";
      inputs = with pkgs; [ rust-script ];
      command = ''
        exec rust-script "$@"
      '';
      description = "Main dotfiles CLI";
      aliases = [
        {name = "rebuild"; description = "Rebuild the system";}
        {name = "update"; description = "Update flake inputs";}
      ];
    }
  \```
    Returns: { ".dots" = <derivation>; ".rebuild" = <derivation>; ".update" = <derivation>; }
  */
  mkShellApp = {
    pkgs,
    /*
    The name of the script to write.

    Type: String
    */
    name,
    /*
    The shell script's text, not including a shebang.

    Type: String
    */
    command,
    /*
    Inputs to add to the shell script's `$PATH` at runtime.

    Type: [String|Derivation]
    */
    inputs ? [],
    /*
    Prefix to add to the command and alias names.

    Type: String
    */
    prefix ? "",
    /*
    List of aliases to create for this command.
    Each alias is an attrset with {name, description, prefix?}.

    Type: [{name: String, description: String, prefix?: String}]
    */
    aliases ? [],
    /*
    Optional description for the command (used in help text).

    Type: String
    */
    description ? null,
    /*
    Extra environment variables to set at runtime.

    Type: AttrSet
    */
    runtimeEnv ? null,
    /*
    `stdenv.mkDerivation`'s `meta` argument.

    Type: AttrSet
    */
    meta ? {},
    /*
    `stdenv.mkDerivation`'s `passthru` argument.

    Type: AttrSet
    */
    passthru ? {},
    /*
    The `checkPhase` to run. Defaults to `shellcheck` on supported
    platforms and `bash -n`.

    The script path will be given as `$target` in the `checkPhase`.

    Type: String
    */
    checkPhase ? null,
    /*
    Checks to exclude when running `shellcheck`, e.g. `[ "SC2016" ]`.

    See <https://www.shellcheck.net/wiki/> for a list of checks.

    Type: [String]
    */
    excludeShellChecks ? [],
    /*
    Extra command-line flags to pass to ShellCheck.

    Type: [String]
    */
    extraShellCheckFlags ? [],
    /*
    Bash options to activate with `set -o` at the start of the script.

    Defaults to `[ "errexit" "nounset" "pipefail" ]`.

    Type: [String]
    */
    bashOptions ? [
      "errexit"
      "nounset"
      "pipefail"
    ],
    /*
    Extra arguments to pass to `stdenv.mkDerivation`.

    :::note{.caution}
    Certain derivation attributes are used internally,
    overriding those could cause problems.
    :::

    Type: AttrSet
    */
    derivationArgs ? {},
    /*
    Whether to inherit the current `$PATH` in the script.

    Type: Bool
    */
    inheritPath ? true,
  }: let
    fullName = "${prefix}${name}";

    #> Create the main application
    mainApp = pkgs.writeShellApplication {
      name = fullName;
      inherit
        bashOptions
        checkPhase
        derivationArgs
        excludeShellChecks
        extraShellCheckFlags
        inheritPath
        runtimeEnv
        ;
      meta =
        meta
        // optionalAttrs (description != null) {
          inherit description;
        };
      passthru =
        passthru
        // {
          inherit aliases prefix;
          cmdDescription = description;
        };
      runtimeInputs = inputs;
      text = command;
    };

    #> Create alias applications
    aliasApps =
      map (aliasSpec: let
        aliasPrefix = aliasSpec.prefix or prefix;
        aliasName = "${aliasPrefix}${aliasSpec.name}";
      in {
        name = aliasName;
        value = pkgs.writeShellApplication {
          name = aliasName;
          runtimeInputs = [mainApp];
          text = ''exec ${fullName} ${aliasSpec.name} "$@"'';
          meta = {
            description = aliasSpec.description or "Alias for ${fullName} ${aliasSpec.name}";
          };
          passthru = {
            aliasOf = mainApp;
            aliasCmd = aliasSpec.name;
          };
        };
      })
      aliases;
  in
    #> Return attrset with main app and all aliases
    {${fullName} = mainApp;}
    // listToAttrs aliasApps;

  /**
    mkScriptWrapper - Copies a POSIX shell script from the dotfiles tree into the nix
    store and wraps it in a named binary. The script is stored immutably at build time,
    making the resulting binary self-contained and reproducible across machines — while
    the source script remains a single canonical file usable anywhere POSIX is available.

    # Arguments
    - pkgs (AttrSet):           Nixpkgs instance
    - name (string):            Name of the resulting binary
    - script (path):            Path to the source shell script
    - extraArgs (list):         Extra arguments to prepend when invoking the script (default: [])

    # Returns
    A derivation providing a binary at `bin/<name>`

    # Example
  \```nix
    mkScriptWrapper {
      inherit pkgs;
      name = "zen";
      script = tree.sh.local + "/packages/wrappers/zen.sh";
    }

    mkScriptWrapper {
      inherit pkgs;
      name = "feet-quake";
      script = tree.sh.local + "/packages/wrappers/feet.sh";
      extraArgs = ["--quake"];
    }
  \```
  */
  mkScriptWrapper = {
    pkgs,
    /*
    Name of the resulting binary.

    Type: String
    */
    name,
    /*
    Path to the source POSIX shell script in the dotfiles tree.
    The script is copied into the nix store at build time.

    Type: Path | String
    */
    script,
    /*
    Extra arguments to prepend when invoking the script.
    Useful for creating mode variants of the same script.

    Type: [String]
    */
    extraArgs ? [],
  }: let
    inherit (pkgs) writeShellScript writeShellScriptBin;
    stored = writeShellScript "${name}.sh" (readFile script);
  in
    writeShellScriptBin name ''
      exec ${stored} ${escapeShellArgs extraArgs} "$@"
    '';

  /**
    mkScriptWrappers - Batch-create script wrappers from an attrset of name → script path.
    All wrappers share the same pkgs instance.

    # Arguments
    - pkgs (AttrSet):   Nixpkgs instance
    - scripts (AttrSet): Mapping of binary name → script path (or { script, extraArgs } attrset)

    # Returns
    A list of derivations, suitable for use in `home.packages` or `environment.systemPackages`

    # Example
  \```nix
    mkScriptWrappers {
      inherit pkgs;
      scripts = {
        zen  = tree.sh.local + "/packages/wrappers/zen.sh";
        feet = tree.sh.local + "/packages/wrappers/feet.sh";
        # With extra args:
        feet-quake   = { script = tree.sh.local + "/packages/wrappers/feet.sh"; extraArgs = ["--quake"];   };
        feet-monitor = { script = tree.sh.local + "/packages/wrappers/feet.sh"; extraArgs = ["--monitor"]; };
      };
    }
  \```
  */
  mkScriptWrappers = {
    pkgs,
    scripts,
  }:
    mapAttrsToList (name: value:
      mkScriptWrapper (
        {inherit pkgs name;}
        // (
          if isPath value || isString value
          then {script = value;}
          else value # already an attrset with { script, extraArgs?, ... }
        )
      ))
    scripts;
in
  exports.internal // {_rootAliases = exports.external;}

```
