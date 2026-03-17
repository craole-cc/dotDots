{
  pkgs,
  inputs,
  lix,
  cfg,
  ...
}: let
  inherit (lix.attrsets.resolution) vscodePackages;

  vcs = [
    #? .gitignore language support
    "codezombiech.gitignore"
    #? git log, file, line history
    "donjayamanne.githistory"
    #? visual git branch graph
    "mhutchie.git-graph"
    #? inline git blame
    "waderyan.gitblame"
    #? LSP for .gitconfig files
    "yy0931.gitconfig-lsp"
    #? jujutsu VCS GUI
    "visualjj.visualjj"
    #? jujutsu keybindings
    "jjk.jjk"
  ];

  ai = [
    #? AI inline completions
    "github.copilot"
    #? AI chat assistant
    "github.copilot-chat"
    #? alternative AI completions
    "codeium.codeium"
  ];

  nix = [
    #? basic Nix syntax
    "bbenoist.nix"
    #? Nix LSP, formatting, eval
    "jnoortheen.nix-ide"
    #? improved Nix highlighting
    "jeff-hykin.better-nix-syntax"
    #? direnv environment integration
    "mkhl.direnv"
    #? Alejandra formatter integration
    "kamadorueda.alejandra"
  ];

  systems = [
    #? Rust LSP
    "rust-lang.rust-analyzer"
    #? LLDB debugger for Rust/C++
    "vadimcn.vscode-lldb"
    #? Rust/Go dependency version checker
    "fill-labs.dependi"
    #? shell script formatter
    "mkhl.shfmt"
    #? shell script linter
    "timonwong.shellcheck"
    #? additional shell formatting
    "foxundermoon.shell-format"
    #? improved shell highlighting
    "jeff-hykin.better-shellscript-syntax"
  ];

  scripting = [
    #? Python LSP and tooling
    "ms-python.python"
    #? Python debugger
    "ms-python.debugpy"
    #? fast Python type checker
    "ms-python.vscode-pylance"
    #? Ruff linter/formatter
    "charliermarsh.ruff"
    #? Nushell language support
    "thenuprojectcontributors.vscode-nushell-lang"
    #? PowerShell LSP and debugger
    "ms-vscode.powershell"
  ];

  web = [
    #? Tailwind CSS intellisense
    "bradlc.vscode-tailwindcss"
    #? Deno runtime and LSP
    "denoland.vscode-deno"
    #? Prettier formatter
    "esbenp.prettier-vscode"
  ];

  markup = [
    #? Markdown linter
    "davidanson.vscode-markdownlint"
    #? Markdown shortcuts, TOC, preview
    "yzhang.markdown-all-in-one"
    #? Export markdown to PDF
    "yzane.markdown-pdf"
    #? CSV column colorizer
    "mechatroner.rainbow-csv"
    #? Mermaid diagram preview in markdown
    "bierner.markdown-mermaid"
    #? GitHub-flavored markdown preview
    "bierner.github-markdown-preview"
    #? YAML LSP and validation
    "redhat.vscode-yaml"
    #? YAML formatter
    "bluebrown.yamlfmt"
    #? TOML LSP and formatter
    "tamasfe.even-better-toml"
    #? INI/properties formatter
    "lkrms.inifmt"
    #? KDL document language support
    "kdl-org.kdl"
    #? Typst LSP and preview
    "myriad-dreamin.tinymist"
    #? Justfile syntax highlighting
    "nefrob.vscode-just-syntax"
    #? mise version manager integration
    "hverlin.mise-vscode"
    #? log file syntax highlighting
    "emilast.logfilehighlighter"
  ];

  infrastructure = [
    #? Docker file support and container management
    "ms-azuretools.vscode-docker"
    #? SQL client and query runner
    "mtxr.sqltools"
    #? SQLite driver for sqltools
    "mtxr.sqltools-driver-sqlite"
    #? Tailscale network integration
    "tailscale.vscode-tailscale"
  ];

  appearance = [
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

  decorations = [
    #? Inline error/warning messages
    "usernamehw.errorlens"
    #? Colorized indentation guides
    "oderwat.indent-rainbow"
    #? Colorize CSS color strings
    "kamikillerto.vscode-colorize"
    #? Highlight color values inline
    "naumovs.color-highlight"
    #? Colorize output/terminal text
    "ibm.output-colorizer"
    #? ANSI escape code renderer
    "iliazeus.vscode-ansi"
    #? Indentation and scope guides
    "spywhere.guides"
    #? Vertical line width ruler
    "lbragile.line-width-indicator"
    #? Colored comment annotations
    "allemandinstable.colorful-comments-refreshed"
    #? Highlight TODO/FIXME tokens
    "jgclark.vscode-todo-highlight"
    #? TODO tree sidebar panel
    "gruntfuggly.todo-tree"
  ];

  productivity = [
    #? Keyboard-driven file browser
    "bodil.file-browser"
    #? Sort workspace folders alphabetically
    "iciclesoft.workspacesort"
    #? Diff two folders side by side
    "moshfeu.compare-folders"
    #? Multi-workspace file search
    "joshmu.periscope"
    #? Text transformation utilities
    "dakara.transformer"
    #? Convert case (camel, snake, kebab…)
    "wmaurer.change-case"
    #? Sort selected lines
    "tyriar.sort-lines"
    #? Toggle editor settings via keybind
    "rebornix.toggle"
    #? .env file support
    "dotenv.dotenv-vscode"
    #? .env syntax highlighting
    "irongeek.vscode-env"
    #? Respect .editorconfig files
    "editorconfig.editorconfig"
    #? Typos spell checker (fast, Rust-based)
    "tekumara.typos-vscode"
    #? CSpell spell checker
    "streetsidesoftware.code-spell-checker"
    #? Spell checking via system dictionary
    "ban.spellright"
    #? Highlight invisible/problematic chars
    "nhoizey.gremlins"
    #? Reload window command
    "natqe.reload"
    #? Run code snippets in any language
    "formulahendry.code-runner"
    #? Test explorer sidebar UI
    "hbenl.vscode-test-explorer"
    #? PlantUML diagram preview and export
    "jebbs.plantuml"
    #? Local dev server with live reload
    "ritwickdey.liveserver"
    #? PDF viewer inside VSCode
    "tomoki1207.pdf"
    #? SVG file preview
    "vitaliymaz.vscode-svg-previewer"
    #? Show import bundle size inline
    "wix.vscode-import-cost"
    #? Restore familiar Windows keybindings
    "smcpeak.default-keys-windows"
  ];

  inherit (cfg) withExtensions;
in {
  extensions = vscodePackages {
    inherit pkgs inputs;
    entries =
      (
        if withExtensions.vcs
        then vcs
        else []
      )
      ++ (
        if withExtensions.ai
        then ai
        else []
      )
      ++ (
        if withExtensions.nix
        then nix
        else []
      )
      ++ (
        if withExtensions.systems
        then systems
        else []
      )
      ++ (
        if withExtensions.scripting
        then scripting
        else []
      )
      ++ (
        if withExtensions.web
        then web
        else []
      )
      ++ (
        if withExtensions.markup
        then markup
        else []
      )
      ++ (
        if withExtensions.infrastructure
        then infrastructure
        else []
      )
      ++ (
        if withExtensions.appearance
        then appearance
        else []
      )
      ++ (
        if withExtensions.decorations
        then decorations
        else []
      )
      ++ (
        if withExtensions.productivity
        then productivity
        else []
      );
  };
}
