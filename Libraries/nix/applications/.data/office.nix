_: {
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
    categories = [
      "office"
      "editor"
    ];
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
    categories = [
      "office"
      "editor"
    ];
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
    categories = [
      "office"
      "editor"
    ];
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
