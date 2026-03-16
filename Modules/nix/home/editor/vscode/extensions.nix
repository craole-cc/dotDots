{
  pkgs,
  inputs,
  system,
  ...
}: let
  marketplace = inputs.nix-vscode-extensions.extensions.${system}.open-vsx;
  vscode = pkgs.vscode-extensions;
in {
  extensions = [
    #~@ Nix
    vscode.bbenoist.nix
    vscode.brettm12345.nixfmt-vscode
    vscode.jeff-hykin.better-nix-syntax
    vscode.jeff-hykin.better-shellscript-syntax
    vscode.jnoortheen.nix-ide
    vscode.mkhl.direnv
    vscode.kamadorueda.alejandra

    #~@ Git
    vscode.codezombiech.gitignore
    vscode.donjayamanne.githistory
    vscode.mhutchie.git-graph
    vscode.waderyan.gitblame
    vscode.yy0931.gitconfig-lsp

    #~@ AI
    vscode.github.copilot
    vscode.github.copilot-chat

    #~@ Shell
    vscode.mkhl.shfmt
    vscode.timonwong.shellcheck
    vscode.foxundermoon.shell-format

    #~@ Rust
    vscode.rust-lang.rust-analyzer
    vscode.vadimcn.vscode-lldb
    vscode.tamasfe.even-better-toml
    vscode.fill-labs.dependi

    #~@ Web
    vscode.bradlc.vscode-tailwindcss
    vscode.denoland.vscode-deno
    vscode.esbenp.prettier-vscode
    vscode.charliermarsh.ruff

    #~@ Language Support
    vscode.ms-vscode.powershell
    vscode.myriad-dreamin.tinymist
    vscode.thenuprojectcontributors.vscode-nushell-lang
    vscode.redhat.vscode-yaml
    vscode.davidanson.vscode-markdownlint
    vscode.mechatroner.rainbow-csv
    vscode.yzane.markdown-pdf
    vscode.yzhang.markdown-all-in-one

    #~@ Python
    vscode.ms-python.python
    vscode.ms-python.debugpy
    vscode.ms-python.vscode-pylance

    #~@ Docker
    vscode.ms-azuretools.vscode-docker

    #~@ Themes
    vscode.catppuccin.catppuccin-vsc
    vscode.uloco.theme-bluloco-dark
    vscode.uloco.theme-bluloco-light
    vscode.dracula-theme.theme-dracula
    vscode.mvllow.rose-pine

    #~@ Icons
    vscode.pkief.material-icon-theme
    vscode.pkief.material-product-icons

    #~@ Visual
    vscode.usernamehw.errorlens
    vscode.oderwat.indent-rainbow
    vscode.kamikillerto.vscode-colorize
    vscode.naumovs.color-highlight
    vscode.ibm.output-colorizer
    vscode.iliazeus.vscode-ansi
    vscode.spywhere.guides

    #~@ Utilities
    vscode.tyriar.sort-lines
    vscode.dotenv.dotenv-vscode
    vscode.editorconfig.editorconfig
    vscode.natqe.reload
    vscode.gruntfuggly.todo-tree
    vscode.formulahendry.code-runner
    vscode.hbenl.vscode-test-explorer
    vscode.jebbs.plantuml
    vscode.ritwickdey.liveserver
    vscode.tomoki1207.pdf
    vscode.wix.vscode-import-cost
    vscode.smcpeak.default-keys-windows
    vscode.tekumara.typos-vscode
    vscode.streetsidesoftware.code-spell-checker
    vscode.visualjj.visualjj

    #~@ Marketplace-only
    marketplace.allemandinstable.colorful-comments-refreshed
    marketplace.brandonkirbyson.vscode-animations
    marketplace.subframe7536.custom-ui-style
    marketplace.be5invis.vscode-custom-css
    marketplace.illixion.vscode-vibrancy-continued
    marketplace.codeium.codeium
    marketplace.elanandkumar.el-vsc-product-icon-theme
    marketplace.lbragile.line-width-indicator
    marketplace.nefrob.vscode-just-syntax
    marketplace.yy0931.gitconfig-lsp
    marketplace.bierner.markdown-mermaid
    marketplace.bierner.github-markdown-preview
    marketplace.bluebrown.yamlfmt
    marketplace.emilast.logfilehighlighter
    marketplace.lkrms.inifmt
    marketplace.mtxr.sqltools
    marketplace.mtxr.sqltools-driver-sqlite
    marketplace.mkhl.shfmt
    marketplace.foxundermoon.shell-format
    marketplace.jjk.jjk
    marketplace.kdl-org.kdl
    marketplace.hverlin.mise-vscode
    marketplace.rebornix.toggle
    marketplace.wmaurer.change-case
    marketplace.joshmu.periscope
    marketplace.nhoizey.gremlins
    marketplace.irongeek.vscode-env
    marketplace.jgclark.vscode-todo-highlight
    marketplace.ban.spellright
    marketplace.tailscale.vscode-tailscale
    marketplace.vitaliymaz.vscode-svg-previewer
    marketplace.bodil.file-browser
    marketplace.iciclesoft.workspacesort
    marketplace.moshfeu.compare-folders
    marketplace.dakara.transformer
  ];
}
