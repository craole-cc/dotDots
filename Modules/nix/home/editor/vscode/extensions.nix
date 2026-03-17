{
  pkgs,
  inputs,
  lib,
  lix,
  ...
}: let
  inherit (lib.lists) filter;
  inherit (lib.strings) splitString;
  inherit (lix.attrsets.resolution) byPaths;
  system = pkgs.stdenv.hostPlatform.system;
  fromNixpkgs = pkgs.vscode-extensions;
  fromMarket = inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace;

  #> Parse "publisher.name" string or { publisher; name; } attrset
  parse = entry:
    if builtins.isString entry
    then let
      parts = splitString "." entry;
    in {
      publisher = builtins.elemAt parts 0;
      name = builtins.elemAt parts 1;
    }
    else entry;

  # Try nixpkgs first, fall back to marketplace
  ext = entry: let
    e = parse entry;
  in
    byPaths {
      attrset = {
        nixpkgs = fromNixpkgs;
        market = fromMarket;
      };
      paths = [
        ["nixpkgs" e.publisher e.name]
        ["market" e.publisher e.name]
      ];
      default = null;
    };

  exts = entries:
    filter (x: x != null) (map ext entries);
in {
  extensions = exts [
    #~@ Nix
    "bbenoist.nix"
    "jnoortheen.nix-ide"
    "jeff-hykin.better-nix-syntax"
    "jeff-hykin.better-shellscript-syntax"
    "mkhl.direnv"
    "kamadorueda.alejandra"

    #~@ Git
    "codezombiech.gitignore"
    "donjayamanne.githistory"
    "mhutchie.git-graph"
    "waderyan.gitblame"
    "yy0931.gitconfig-lsp"

    #~@ AI
    "github.copilot"
    "github.copilot-chat"
    "codeium.codeium"

    #~@ Shell
    "mkhl.shfmt"
    "timonwong.shellcheck"
    "foxundermoon.shell-format"

    #~@ Rust
    "rust-lang.rust-analyzer"
    "vadimcn.vscode-lldb"
    "tamasfe.even-better-toml"
    "fill-labs.dependi"

    #~@ Web
    "bradlc.vscode-tailwindcss"
    "denoland.vscode-deno"
    "esbenp.prettier-vscode"
    "charliermarsh.ruff"

    #~@ Language Support
    "ms-vscode.powershell"
    "myriad-dreamin.tinymist"
    "thenuprojectcontributors.vscode-nushell-lang"
    "redhat.vscode-yaml"
    "davidanson.vscode-markdownlint"
    "mechatroner.rainbow-csv"
    "yzane.markdown-pdf"
    "yzhang.markdown-all-in-one"
    "nefrob.vscode-just-syntax"
    "kdl-org.kdl"
    "jjk.jjk"
    "hverlin.mise-vscode"
    "bluebrown.yamlfmt"
    "lkrms.inifmt"
    "emilast.logfilehighlighter"

    #~@ Python
    "ms-python.python"
    "ms-python.debugpy"
    "ms-python.vscode-pylance"

    #~@ Docker
    "ms-azuretools.vscode-docker"

    #~@ Database
    "mtxr.sqltools"
    "mtxr.sqltools-driver-sqlite"

    #~@ Themes
    "catppuccin.catppuccin-vsc"
    "uloco.theme-bluloco-dark"
    "uloco.theme-bluloco-light"
    "dracula-theme.theme-dracula"
    "mvllow.rose-pine"

    #~@ Icons
    "pkief.material-icon-theme"
    "pkief.material-product-icons"
    "elanandkumar.el-vsc-product-icon-theme"

    #~@ Visual
    "usernamehw.errorlens"
    "oderwat.indent-rainbow"
    "kamikillerto.vscode-colorize"
    "naumovs.color-highlight"
    "ibm.output-colorizer"
    "iliazeus.vscode-ansi"
    "spywhere.guides"
    "lbragile.line-width-indicator"
    "bierner.markdown-mermaid"
    "bierner.github-markdown-preview"
    "allemandinstable.colorful-comments-refreshed"
    "brandonkirbyson.vscode-animations"
    "subframe7536.custom-ui-style"
    "be5invis.vscode-custom-css"
    "illixion.vscode-vibrancy-continued"

    #~@ Utilities
    "tyriar.sort-lines"
    "dotenv.dotenv-vscode"
    "editorconfig.editorconfig"
    "natqe.reload"
    "gruntfuggly.todo-tree"
    "formulahendry.code-runner"
    "hbenl.vscode-test-explorer"
    "jebbs.plantuml"
    "ritwickdey.liveserver"
    "tomoki1207.pdf"
    "wix.vscode-import-cost"
    "smcpeak.default-keys-windows"
    "tekumara.typos-vscode"
    "streetsidesoftware.code-spell-checker"
    "visualjj.visualjj"
    "wmaurer.change-case"
    "joshmu.periscope"
    "nhoizey.gremlins"
    "irongeek.vscode-env"
    "jgclark.vscode-todo-highlight"
    "ban.spellright"
    "tailscale.vscode-tailscale"
    "vitaliymaz.vscode-svg-previewer"
    "bodil.file-browser"
    "iciclesoft.workspacesort"
    "moshfeu.compare-folders"
    "rebornix.toggle"
    "dakara.transformer"
  ];
}
