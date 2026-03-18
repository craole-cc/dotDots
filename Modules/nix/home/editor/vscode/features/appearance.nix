{
  lix,
  lib,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
  inherit (lib.modules) mkDefault;
in
  mkVSCodeFeature {
    extensions = [
      #? Catppuccin color theme
      "catppuccin.catppuccin-vsc"
      #? Bluloco dark theme
      "uloco.theme-bluloco-dark"
      #? Bluloco light theme
      "uloco.theme-bluloco-light"
      #? Dracula color theme
      "dracula-theme.theme-dracula"
      #? Rosé Pine color theme
      "mvllow.rose-pine"
      #? Material file/folder icons
      "pkief.material-icon-theme"
      #? Material UI chrome icons
      "pkief.material-product-icons"
      #? Alternative product icon theme
      "elanandkumar.el-vsc-product-icon-theme"
      #? Smooth UI animations
      "brandonkirbyson.vscode-animations"
      #? Custom CSS/JS UI injection
      "subframe7536.custom-ui-style"
      #? Custom CSS overrides
      "be5invis.vscode-custom-css"
      #? Acrylic/vibrancy window effect
      "illixion.vscode-vibrancy-continued"
    ];
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
      "workbench.colorTheme" = mkDefault "Catppuccin Frappé";
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
      "custom-ui-style.background.syncURL" = "file:///$\\{env:WALLPAPER\\}";
      "custom-ui-style.background.size" = "cover";
      "custom-ui-style.background.position" = "center";
      "custom-ui-style.background.opacity" = 0.94;
      "custom-ui-style.reloadWithoutPrompting" = true;
      "custom-ui-style.watch" = true;

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
    };
  }
