{
  userSettings = {
    # Window & Workbench
    "window.autoDetectColorScheme" = true;
    "window.autoDetectHighContrast" = true;
    "window.titleBarStyle" = "custom";
    "window.menuBarVisibility" = "compact";
    "workbench.startupEditor" = "none";

    # Workbench Theme
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.productIconTheme" = "material-product-icons";
    # "workbench.productIconTheme" = "el-vsc-v1-icons";
    "workbench.preferredLightColorTheme" = "Bluloco Light Italic";
    "workbench.preferredDarkColorTheme" = "Monokai";
    "workbench.panel.defaultLocation" = "bottom";

    # Color Customizations
    "workbench.colorCustomizations" = {
      "editorGroupHeader.tabsBackground" = "#ffffff00";
      "statusBar.background" = "#ffffff00";
      "statusBar.border" = "#3c69e750";
    };

    # Workbench Associations
    "workbench.editorAssociations" = {
      "*.copilotmd" = "vscode.markdown.preview.editor";
      # "*.pdf" = "pdf.view";
    };

    # Material Icon Theme
    "material-icon-theme.activeIconPack" = "react";
    "material-icon-theme.hidesExplorerArrows" = true;
    "material-icon-theme.files.color" = "#e8ddd8";
    "material-icon-theme.folders.color" = "#81c8be";

    "material-icon-theme.files.associations" = {
      ".envrc" = "ember";
      ".ignore" = "mocha";
      ".shellcheckrc" = "astyle";
      ".treefmt.toml" = "taze";
      "rust-toolchain" = "rust";
      "rust-toolchain.toml" = "rust";
    };

    "material-icon-theme.folders.associations" = {
      "users" = "admin";
      "overlays" = "plugin";
      "hosts" = "client";
      "systems" = "client";
      "media" = "video";
      "types" = "Enum";
      "methods" = "Config";
      "traits" = "Tools";
      "dots" = "Cluster";
      ".cargo" = "config";
      "options" = "tasks";
      "desktops" = "interfaces";
    };

    # Line Width Indicator
    "LWI.breakpoints" = [
      {
        "color" = "rgb(0, 255, 0, 0.6)";
        "column" = 54;
      }
      {
        "color" = "rgb(255, 255, 0, 0.6)";
        "column" = 69;
      }
      {
        "color" = "rgb(255, 0, 0, 0.6)";
        "column" = 79;
      }
    ];
    "LWI.style.fontStyle" = "italic";
    "LWI.style.fontWeight" = "100";
  };
}
