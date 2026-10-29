{
  pkgs,
  style,
  ...
}: let
  # Match the FHS profile until the locked catalogues include this release.
  materialIcons = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "PKief";
      name = "material-icon-theme";
      version = "5.40.0";
      sha256 = "sha256-VbVl8gCIGr/YB7r5vlL85F/VL+8BO6cbD4OUmEzhrgY=";
    };
  };
in {
  extensions = [
    #? Material Design Icons for VS Code
    materialIcons
    #? Material Product Icons for VS Code
    "PKief.material-product-icons"
    "elanandkumar.el-vsc-product-icon-theme"
  ];

  settings = {
    workbench = {
      #> Active file icon theme.
      #! overridden (default: "vs-seti")
      iconTheme = "material-icon-theme";
      #> Active product icon theme.
      #! overridden (default: "Default")
      productIconTheme = "el-vsc-v1-icons";
    };

    material-icon-theme = {
      # ── material-icon-theme ─────────────────────────────────────────────
      #> Active icon pack.
      #?  - angular | angular_ngrx | react | react_redux | roblox | qwik
      #?  - vue | vue_vuex | nest | bashly | none
      #! overridden (default: "angular")
      activeIconPack = "react";
      #> Hide explorer arrows before folder.
      #! overridden (default: false)
      hidesExplorerArrows = true;

      files = {
        #> File icon colour.
        #! overridden (default: "#90a4ae")
        color = style.color.accent;

        #~@ File Associations
        #! overridden (default: {})
        associations = {
          ".editorconfig" = "editorconfig";
          ".mise.toml" = "jenkins";
          ".treefmt.toml" = "taze";
          "editorconfig" = "editorconfig";
          "mise.toml" = "jenkins";
          "treefmt.toml" = "taze";
          "treefmt/config.toml" = "taze";
        };

        #~@ Custom file icon clones
        #! overridden (default: [])
        customClones = [
          {
            name = "rust-entrypoint";
            base = "rstack";
            color = "orange-800";
            lightColor = "orange-800";
            fileNames = [
              ".cargo/config.toml"
              ".rust-analyzer.toml"
              ".rustfmt.toml"
              "Cargo.toml"
              "lib.rs"
              "main.rs"
              "mod.rs"
              "rust-analyzer.toml"
              "rust-toolchain"
              "rust-toolchain.toml"
              "rustfmt.toml"
            ];
          }
          {
            name = "nix-entrypoint";
            base = "nix";
            color = "cyan-300";
            lightColor = "cyan-600";
            fileNames = [
              "configuration.nix"
              "default.nix"
              "flake.nix"
              "shell.nix"
            ];
          }
          {
            name = "dotenv";
            base = "key";
            color = "amber-300";
            lightColor = "amber-600";
            fileNames = [
              ".env"
              ".envrc"
              "env"
              "envrc"
            ];
          }
          {
            name = "sublime-text";
            base = "sublime";
            color = "amber-300";
            lightColor = "amber-600";
            fileNames = [
              ".sublime"
              "Preferences.sublime-settings"
              "sublime"
              "sublime-settings"
            ];
          }
          {
            name = "markdownlinter";
            base = "markdownlint";
            color = "blue-400";
            lightColor = "blue-500";
            fileNames = [
              ".markdownlint-cli2.yaml"
              ".markdownlint.yaml"
              "markdownlint-cli2.yaml"
              "markdownlint.yaml"
            ];
          }
          {
            name = "dots";
            base = "ionic";
            color = "teal-300";
            lightColor = "teal-600";
            fileNames = [
              ".dots.conf"
              ".dots.json"
              ".dots.toml"
              ".dots.txt"
              ".dotsrc"
              ".dotsrc.fish"
              ".dotsrc.nu"
              ".dotsrc.ps1"
              ".dotsrc.sh"
              "dots.json"
              "dots.toml"
            ];
          }
        ];
      };

      folders = {
        #> Folder icon colour.
        #! overridden (default: "#90a4ae")
        color = style.color.accent;
        #> Folder icon theme.
        #?  - specific | classic | none
        theme = "specific";

        # ── Folder associations ─────────────────────────────────────────────
        #! overridden (default: {})
        associations = {
          "_" = "base";
          ".cargo" = "config";
          "Advent-of-Code" = "Middleware";
          "ai" = "robot";
          "benches" = "debug";
          "challenges" = "Cluster";
          "crates" = "Packages";
          "day-*" = "job";
          "days" = "job";
          "desktops" = "interfaces";
          "dots" = "Cluster";
          "hosts" = "client";
          "media" = "video";
          "methods" = "Config";
          "options" = "tasks";
          "overlays" = "plugin";
          "polar" = "plastic";
          "rails" = "Debug";
          "systems" = "client";
          "traits" = "Tools";
          "trivial" = "sandbox";
          "types" = "Enum";
          "users" = "admin";
        };

        #~@ Custom folder icon clones
        #! overridden (default: [])
        customClones = [
          {
            name = "users";
            base = "admin";
            color = "light-green-300";
            lightColor = "light-green-700";
            folderNames = ["people" "roles" "user" "users"];
          }
          {
            name = "desktops";
            base = "desktop";
            color = "purple-300";
            lightColor = "orange-700";
            folderNames = ["control" "desktop" "desktops"];
          }
          {
            name = "editor";
            base = "skills";
            color = "blue-gray-600";
            lightColor = "blue-gray-700";
            folderNames = ["editor" "helix" "neovim" "nvim" "zed"];
          }
          {
            name = "hosts";
            base = "client";
            color = "blue-gray-400";
            lightColor = "orange-700";
            folderNames = ["host" "hosts" "machine" "machines"];
          }
          {
            name = "programs";
            base = "app";
            color = "cyan-300";
            lightColor = "green-700";
            folderNames = ["program" "programs"];
          }
          {
            name = "macros";
            base = "middleware";
            color = "blue-400";
            lightColor = "blue-500";
            folderNames = ["constructors" "macros"];
          }
          {
            name = "shell";
            base = "scripts";
            color = "blue-gray-600";
            lightColor = "blue-gray-500";
            folderNames = ["bash" "posix" "sh" "shell" "shells" "shellscript"];
          }
          {
            name = "err";
            base = "error";
            color = "purple-400";
            lightColor = "red-500";
            folderNames = ["err" "erks" "error"];
          }
          {
            name = "filesystem";
            base = "resource";
            color = "deep-purple-400";
            lightColor = "deep-purple-500";
            folderNames = ["file" "files" "filesystem" "io" "system"];
          }
          {
            name = "folder";
            base = "archive";
            color = "deep-purple-300";
            lightColor = "deep-purple-400";
            folderNames = ["folder" "folders"];
          }
          {
            name = "compression";
            base = "archive";
            color = "pink-400";
            lightColor = "pink-600";
            folderNames = ["compress" "compression" "extract" "extractor"];
          }
          {
            name = "internal";
            base = "import";
            color = "green-300";
            lightColor = "green-400";
            folderNames = ["importer" "importers" "internal" "local"];
          }
          {
            name = "external";
            base = "packages";
            color = "green-400";
            lightColor = "green-700";
            folderNames = ["external"];
          }
          {
            name = "workspace";
            base = "project";
            color = "blue-400";
            lightColor = "blue-700";
            folderNames = ["workspace"];
          }
          {
            name = "nixos";
            base = "quasar";
            color = "cyan-800";
            lightColor = "cyan-700";
            folderNames = [".nix" "flake" "flakes" "nix" "nixos"];
          }
          {
            name = "movie";
            base = "video";
            color = "orange-800";
            lightColor = "orange-400";
            folderNames = ["imdb" "movie"];
          }
          {
            name = "string";
            base = "storybook";
            color = "light-blue-800";
            lightColor = "light-blue-400";
            folderNames = ["derive" "grammar" "string" "strings" "terminology" "terms" "vocabulary"];
          }
          {
            name = "lists";
            base = "enum";
            color = "teal-600";
            lightColor = "teal-400";
            folderNames = ["list" "lists"];
          }
          {
            name = "sets";
            base = "less";
            color = "teal-600";
            lightColor = "teal-400";
            folderNames = ["attr" "attrsets" "set" "sets"];
          }
          {
            name = "hardware";
            base = "core";
            color = "blue-gray-400";
            lightColor = "blue-gray-700";
            folderNames = ["chip" "hardware" "memory"];
          }
          {
            name = "format";
            base = "custom";
            color = "pink-800";
            lightColor = "pink-400";
            folderNames = ["art" "customize" "fmt" "format"];
          }
          {
            name = "time";
            base = "temp";
            color = "teal-800";
            lightColor = "teal-400";
            folderNames = ["clock" "date" "ephemeral" "time"];
          }
          {
            name = "registry";
            base = "scons";
            color = "purple-800";
            lightColor = "purple-400";
            folderNames = ["register" "registry"];
          }
          {
            name = "sqlx";
            base = "database";
            color = "orange-800";
            lightColor = "orange-400";
            folderNames = [".sqlx" "sqlx"];
          }
          {
            name = "unit";
            base = "interceptor";
            color = "brown-800";
            lightColor = "brown-400";
            folderNames = ["distance" "measure" "period" "persistent" "range" "span"];
          }
        ];
      };
      #> Icon opacity (0–1).
      opacity = 1;
      #> Icon saturation (0–1).
      saturation = 1;
      #> Enable logging to the output channel.
      enableLogging = false;
      #> Log level.
      logLevel = "info";

      #~@ Root Folders
      #> Custom root-folder associations.
      "rootFolders.associations" = {};
      #> Root-folder icon colour.
      rootFolders.color = style.color.accent;

      # ── Custom language icon clones ─────────────────────────────────────
      #! overridden (default: [])
      languages.customClones = [
        {
          name = "ahk-clone";
          base = "autohotkey";
          color = "blue-400";
          lightColor = "gray-600";
          ids = ["ahk2"];
        }
      ];
    };
  };
}
