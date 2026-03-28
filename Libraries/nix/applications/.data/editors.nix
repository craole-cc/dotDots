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
