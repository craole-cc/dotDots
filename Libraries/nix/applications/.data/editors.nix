_: {
  clion = {
    names = {
      package = "jetbrains.clion";
      command = "clion";
      class = "jetbrains-clion";
    };
    exec = "clion";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  cursor = {
    names = {
      package = "cursor";
      command = "cursor";
      class = "cursor";
      title = "Cursor";
    };
    exec = "cursor";
    categories = [
      "editor"
      "ide"
    ];
    family = "vscode";
    channel = "stable";
  };

  datagrip = {
    names = {
      package = "jetbrains.datagrip";
      command = "datagrip";
      class = "jetbrains-datagrip";
    };
    exec = "datagrip";
    categories = [
      "editor"
      "database"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  emacs = {
    names = {
      package = "emacs";
      command = "emacs";
      class = "Emacs";
    };
    exec = "emacs";
    categories = [
      "editor"
      "file-manager"
    ];
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
    categories = [ "editor" ];
    family = "emacs";
    channel = "stable";
  };

  fleet = {
    names = {
      package = "jetbrains.fleet";
      command = "fleet";
      class = "Fleet";
    };
    exec = "fleet";
    categories = [ "editor" ];
    family = "jetbrains";
    channel = "beta";
  };

  fresh = {
    names = {
      package = "fresh-editor";
      command = "fresh";
      title = "Fresh";
    };
    exec = "fresh";
    needsTerminal = true;
    categories = [ "editor" ];
    channel = "stable";
  };

  gedit = {
    names = {
      package = "gedit";
      command = "gedit";
      class = "org.gnome.gedit";
    };
    exec = "gedit";
    categories = [ "editor" ];
    channel = "stable";
  };

  goland = {
    names = {
      package = "jetbrains.goland";
      command = "goland";
      class = "jetbrains-goland";
    };
    exec = "goland";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
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
    categories = [ "editor" ];
    channel = "stable";
  };

  idea-oss = {
    names = {
      package = "jetbrains.idea-oss";
      command = "idea-oss";
      class = "jetbrains-idea";
    };
    exec = "idea-oss";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  intellij = {
    names = {
      package = "jetbrains.idea-ultimate";
      command = "idea-ultimate";
      class = "jetbrains-idea";
      title = "IntelliJ IDEA Ultimate";
    };
    exec = "idea-ultimate";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  kate = {
    names = {
      package = "kate";
      command = "kate";
      class = "org.kde.kate";
    };
    exec = "kate";
    categories = [ "editor" ];
    channel = "stable";
  };

  lapce = {
    names = {
      package = "lapce";
      command = "lapce";
      class = "dev.lapce.lapce";
    };
    exec = "lapce";
    categories = [
      "editor"
      "ide"
    ];
    channel = "stable";
  };

  lite-xl = {
    names = {
      package = "lite-xl";
      command = "lite-xl";
      class = "lite-xl";
    };
    exec = "lite-xl";
    categories = [ "editor" ];
    channel = "stable";
  };

  micro = {
    names = {
      package = "micro";
      command = "micro";
      title = "micro";
    };
    exec = "micro";
    needsTerminal = true;
    categories = [ "editor" ];
    channel = "stable";
  };

  mousepad = {
    names = {
      package = "mousepad";
      command = "mousepad";
      class = "org.xfce.mousepad";
    };
    exec = "mousepad";
    categories = [ "editor" ];
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
    categories = [ "editor" ];
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
    categories = [ "editor" ];
    family = "vim";
    channel = "stable";
  };

  pycharm = {
    names = {
      package = "jetbrains.pycharm-professional";
      command = "pycharm-professional";
      class = "jetbrains-pycharm";
    };
    exec = "pycharm-professional";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  pycharm-oss = {
    names = {
      package = "jetbrains.pycharm-oss";
      command = "pycharm-oss";
      class = "jetbrains-pycharm";
    };
    exec = "pycharm-oss";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  rust-rover = {
    names = {
      package = "jetbrains.rust-rover";
      command = "rust-rover";
      class = "jetbrains-rustrover";
      title = "RustRover";
    };
    exec = "rust-rover";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  sublime = {
    names = {
      package = "sublime4";
      command = "subl";
      class = "sublime_text";
      title = "Sublime Text";
    };
    exec = "subl";
    categories = [ "editor" ];
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
    categories = [ "editor" ];
    family = "vim";
    channel = "stable";
  };

  vscode = {
    names = {
      package = "vscode";
      command = "code";
      class = "code";
      title = "Visual Studio Code";
    };
    exec = "code";
    categories = [
      "editor"
      "ide"
    ];
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
    categories = [
      "editor"
      "ide"
    ];
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
    categories = [
      "editor"
      "ide"
    ];
    family = "vscode";
    channel = "stable";
  };

  webstorm = {
    names = {
      package = "jetbrains.webstorm";
      command = "webstorm";
      class = "jetbrains-webstorm";
    };
    exec = "webstorm";
    categories = [
      "editor"
      "ide"
    ];
    family = "jetbrains";
    channel = "stable";
  };

  windsurf = {
    names = {
      package = "windsurf";
      command = "windsurf";
      class = "windsurf";
      title = "Windsurf";
    };
    exec = "windsurf";
    categories = [
      "editor"
      "ide"
    ];
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
    categories = [
      "editor"
      "ide"
    ];
    channel = "stable";
  };

  zed-preview = {
    names = {
      package = "zed-editor";
      command = "zeditor";
      class = "dev.zed.Zed-Preview";
    };
    exec = "zeditor --preview";
    categories = [
      "editor"
      "ide"
    ];
    channel = "beta";
  };
}
