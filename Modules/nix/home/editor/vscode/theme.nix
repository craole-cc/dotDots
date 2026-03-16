{
  userSettings = {
    # Window
    "window.autoDetectColorScheme" = true;
    "window.autoDetectHighContrast" = false;
    "window.titleBarStyle" = "native";
    "window.menuBarVisibility" = "toggle";
    "window.customTitleBarVisibility" = "never";
    "window.zoomPerWindow" = true;

    # Workbench
    "workbench.startupEditor" = "none";
    "workbench.colorTheme" = "Catppuccin Frappé";
    "workbench.preferredDarkColorTheme" = "Catppuccin Frappé";
    "workbench.preferredLightColorTheme" = "Catppuccin Latte";
    "workbench.iconTheme" = "material-icon-theme";
    "workbench.productIconTheme" = "material-product-icons";
    "workbench.panel.defaultLocation" = "bottom";
    "workbench.sideBar.location" = "right";
    "workbench.editor.empty.hint" = "hidden";
    "workbench.editor.revealIfOpen" = true;
    "workbench.quickOpen.preserveInput" = true;
    "workbench.commandPalette.preserveInput" = true;
    "workbench.experimental.share.enabled" = true;
    "workbench.settings.openDefaultKeybindings" = true;
    "workbench.statusBar.visible" = true;
    "workbench.editorAssociations" = {
      "*.copilotmd" = "vscode.markdown.preview.editor";
      "*.pdf" = "pdf.view";
      "*.db" = "default";
    };
    "workbench.colorCustomizations" = {
      "editorGroupHeader.tabsBackground" = "#ffffff00";
      "statusBar.background" = "#ffffff00";
      "statusBar.border" = "#3c69e750";
    };

    # Material Icon Theme
    "material-icon-theme.activeIconPack" = "react";
    "material-icon-theme.hidesExplorerArrows" = true;
    "material-icon-theme.files.color" = "#e8ddd8";
    "material-icon-theme.folders.color" = "#81c8be";
    "material-icon-theme.files.associations" = {
      ".envrc" = "ember";
      ".ignore" = "mocha";
      ".cargo/config.toml" = "rust";
      "Cargo.toml" = "rust";
      ".rust-analyzer.toml" = "rust";
      "rust-analyzer.toml" = "rust";
      "rust-toolchain" = "rust";
      "rust-toolchain.toml" = "rust";
      ".rustfmt.toml" = "rust";
      "rustfmt.toml" = "rust";
      ".treefmt.toml" = "taze";
      "treefmt/config.toml" = "taze";
      "treefmt.toml" = "taze";
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
    "material-icon-theme.folders.customClones" = [
      {
        "name" = "rust-entrypoint";
        "base" = "rust";
        "color" = "amber-300";
        "lightColor" = "amber-600";
        "fileNames" = ["lib.rs" "main.rs" "mod.rs" "Cargo.toml"];
      }
      {
        "name" = "nix-entrypoint";
        "base" = "nix";
        "color" = "green-300";
        "lightColor" = "green-600";
        "fileNames" = ["default.nix" "flake.nix" "shell.nix" "configuration.nix"];
      }
      {
        "name" = "users";
        "base" = "admin";
        "color" = "light-green-300";
        "lightColor" = "light-green-700";
        "folderNames" = ["users" "user" "people" "roles"];
      }
      {
        "name" = "desktops";
        "base" = "desktop";
        "color" = "purple-300";
        "lightColor" = "orange-700";
        "folderNames" = ["desktops" "desktop" "control"];
      }
      {
        "name" = "hosts";
        "base" = "client";
        "color" = "blue-gray-400";
        "lightColor" = "orange-700";
        "folderNames" = ["hosts" "host" "machine" "machines"];
      }
      {
        "name" = "programs";
        "base" = "app";
        "color" = "cyan-300";
        "lightColor" = "green-700";
        "folderNames" = ["program" "programs"];
      }
      {
        "name" = "macros";
        "base" = "middleware";
        "color" = "blue-400";
        "lightColor" = "blue-500";
        "folderNames" = ["constructors" "macros"];
      }
      {
        "name" = "shell";
        "base" = "scripts";
        "color" = "blue-gray-600";
        "lightColor" = "blue-gray-500";
        "folderNames" = ["shell" "shellscript" "bash" "sh" "posix"];
      }
      {
        "name" = "nixos";
        "base" = "nix";
        "color" = "cyan-800";
        "lightColor" = "cyan-700";
        "folderNames" = ["nixos" "flake" "flakes" "nix"];
      }
      {
        "name" = "dots";
        "base" = "ionic";
        "color" = "teal-300";
        "lightColor" = "teal-600";
        "fileNames" = [".dots.json" "dots.json" ".dotsrc" ".dotsrc.sh" ".dotsrc.nu"];
      }
    ];
    "material-icon-theme.languages.customClones" = [
      {
        "name" = "ahk-clone";
        "base" = "autohotkey";
        "color" = "blue-400";
        "lightColor" = "grey-600";
        "ids" = ["ahk2"];
      }
    ];

    # Line Width Indicator
    "LWI.breakpoints" = [
      {
        "color" = "rgb(0, 255, 0, 0.6)";
        "column" = 54;
      }
      {
        "color" = "rgb(244, 180, 0, 0.6)";
        "column" = 68;
      }
      {
        "color" = "rgb(255, 0, 0, 0.6)";
        "column" = 79;
      }
    ];
    "LWI.style.fontStyle" = "italic";
    "LWI.style.fontWeight" = "100";

    # Animations
    "animations.Install-Method" = "Custom UI Style";
    "animations.CursorAnimation" = true;
    "animations.CursorAnimationOptions" = {
      "Color" = "teal";
      "CursorStyle" = "block";
      "TrailLength" = 8;
    };

    # Custom UI Style
    "custom-ui-style.font.sansSerif" = "'Maple Mono NF', 'Monaspace Radon', 'Dank Mono'";
    "custom-ui-style.font.monospace" = "'Maple Mono NF', 'VictorMono Nerd Font', 'Dank Mono', 'Hack Nerd Font', monospace";
    "custom-ui-style.background.syncURL" = "file:///$\{env:WALLPAPER\}";
    "custom-ui-style.background.size" = "cover";
    "custom-ui-style.background.position" = "center";
    "custom-ui-style.background.opacity" = 0.94;
    "custom-ui-style.reloadWithoutPrompting" = true;
    "custom-ui-style.watch" = true;

    # Colorful Comments
    "colorful-comments-refreshed.tags" = [
      {
        "tag" = "@";
        "italic" = true;
        "backgroundColor" = "#89a25722";
        "color" = "#89a257";
      }
      {
        "tag" = "~@";
        "italic" = true;
        "backgroundColor" = "#89a25722";
        "color" = "#89a257";
      }
      {
        "tag" = "{";
        "italic" = true;
        "backgroundColor" = "#2aaaa222";
        "color" = "#2aaaa2";
      }
      {
        "tag" = "!";
        "backgroundColor" = "transparent";
        "color" = "#ff0000";
      }
      {
        "tag" = "/";
        "italic" = true;
        "backgroundColor" = "#bd8af41a";
        "color" = "#bd8af4";
      }
      {
        "tag" = "|";
        "italic" = true;
        "color" = "hsl(148, 70%, 50%)";
      }
      {
        "tag" = "region";
        "italic" = true;
        "backgroundColor" = "#bd8af41a";
        "color" = "#bd8af4";
      }
      {
        "tag" = "endregion";
        "italic" = true;
        "backgroundColor" = "#bd8af41a";
        "color" = "#bd8af4";
      }
      {
        "tag" = "HELP";
        "italic" = true;
        "backgroundColor" = "transparent";
        "color" = "#fed200";
      }
      {
        "tag" = "shellcheck";
        "italic" = true;
        "backgroundColor" = "transparent";
        "color" = "#fd7b30";
      }
      {
        "tag" = "DOC ";
        "italic" = true;
        "backgroundColor" = "transparent";
        "color" = "#08c3d4";
      }
      {
        "tag" = "USAGE ";
        "italic" = true;
        "backgroundColor" = "transparent";
        "color" = "#08c3d4";
      }
      {
        "tag" = " http";
        "italic" = true;
        "backgroundColor" = "transparent";
        "color" = "#3498DB";
      }
      {
        "tag" = " -- ";
        "bold" = true;
        "backgroundColor" = "transparent";
        "color" = "#3498DB";
      }
      {
        "tag" = ".";
        "bold" = true;
        "backgroundColor" = "transparent";
        "color" = "#3498DB";
      }
      {
        "tag" = "result:";
        "bold" = true;
        "backgroundColor" = "transparent";
        "color" = "#3498DB";
      }
      {
        "tag" = "todo";
        "italic" = true;
        "underline" = true;
        "backgroundColor" = "transparent";
        "color" = "hsla(27, 90%, 55%, 0.75)";
      }
      {
        "tag" = "def";
        "backgroundColor" = "transparent";
        "color" = "hsla(43, 50%, 50%, 0.95)";
      }
      {
        "tag" = "=";
        "backgroundColor" = "transparent";
        "color" = "hsla(335, 80%, 38%, 0.75)";
      }
      {
        "tag" = "+";
        "backgroundColor" = "transparent";
        "color" = "hsla(335, 80%, 38%, 0.75)";
      }
      {
        "tag" = ">";
        "bold" = true;
        "italic" = true;
        "underline" = true;
        "backgroundColor" = "transparent";
        "color" = "hsla(162, 70%, 30%, 0.95)";
      }
      {
        "tag" = "?";
        "bold" = true;
        "italic" = true;
        "underline" = true;
        "backgroundColor" = "transparent";
        "color" = "hsla(162, 70%, 30%, 0.5)";
      }
      {
        "tag" = "╔";
        "italic" = true;
        "backgroundColor" = "hsla(300,86%,47%, 0.15)";
        "color" = "hsl(300,86%,47%)";
      }
      {
        "tag" = "║";
        "italic" = true;
        "backgroundColor" = "hsla(300,86%,47%, 0.15)";
        "color" = "hsl(300,86%,47%)";
      }
      {
        "tag" = "╠";
        "italic" = true;
        "backgroundColor" = "hsla(300,86%,47%, 0.15)";
        "color" = "hsl(300,86%,47%)";
      }
      {
        "tag" = "╚";
        "italic" = true;
        "backgroundColor" = "hsla(300,86%,47%, 0.15)";
        "color" = "hsl(300,86%,47%)";
      }
    ];
  };
}
