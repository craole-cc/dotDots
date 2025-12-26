{lib, ...}: let
  inherit (lib.attrsets) attrByPath;
  inherit (lib.lists) filter unique;

  # Get editor info (cmd + pkg) from name
  info = {
    pkgs,
    name,
  }:
    {
      helix = {
        cmd = "hx";
        pkg = pkgs.helix;
      };
      neovim = {
        cmd = "nvim";
        pkg = pkgs.neovim;
      };
      vim = {
        cmd = "vim";
        pkg = pkgs.vim;
      };
      nano = {
        cmd = "nano";
        pkg = pkgs.nano;
      };
      emacs = {
        cmd = "emacs";
        pkg = pkgs.emacs;
      };
      vscode = {
        cmd = "code";
        pkg = pkgs.vscode;
      };
      "vscode-insiders" = {
        cmd = "code-insiders";
        pkg = pkgs.vscode-insiders;
      };
      vscodium = {
        cmd = "codium";
        pkg = pkgs.vscodium;
      };
      zed = {
        cmd = "zeditor";
        pkg = pkgs.zed-editor;
      };
      sublime = {
        cmd = "subl";
        pkg = pkgs.sublime4;
      };
      atom = {
        cmd = "atom";
        pkg = pkgs.atom;
      };
    }.${
      name
    } or {
      cmd = name;
      pkg = null;
    };

  # Extract packages from editor config
  packages = {
    pkgs,
    editorConfig ? {},
  }: let
    ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
    ttySecondary = attrByPath ["tty" "secondary"] null editorConfig;
    guiPrimary = attrByPath ["gui" "primary"] null editorConfig;
    guiSecondary = attrByPath ["gui" "secondary"] null editorConfig;

    getInfo = name:
      if name != null
      then
        info {
          inherit pkgs;
          inherit name;
        }
      else null;

    allInfos = filter (i: i != null) [
      (getInfo ttyPrimary)
      (getInfo ttySecondary)
      (getInfo guiPrimary)
      (getInfo guiSecondary)
    ];

    allPkgs = map (i: i.pkg) allInfos;
  in
    unique (filter (p: p != null) allPkgs);

  # Get commands from editor config
  commands = {
    pkgs,
    editorConfig ? {},
  }: let
    ttyPrimary = attrByPath ["tty" "primary"] "helix" editorConfig;
    guiPrimary = attrByPath ["gui" "primary"] null editorConfig;

    ttyInfo = info {
      inherit pkgs;
      name = ttyPrimary;
    };
    guiInfo =
      if guiPrimary != null
      then
        info {
          inherit pkgs;
          name = guiPrimary;
        }
      else ttyInfo;
  in {
    editor = ttyInfo.cmd;
    visual = guiInfo.cmd;
  };

  exports = {
    inherit info packages commands;
  };
in
  exports
  // {
    _rootAliases = {
      editorInfo = info;
      editorPackages = packages;
      editorCommands = commands;
    };
  }
