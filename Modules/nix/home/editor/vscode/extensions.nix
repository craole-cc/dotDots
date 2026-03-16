{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  fromNixpkgs = pkgs.vscode-extensions;
  fromMarket = inputs.nix-vscode-extensions.extensions.${system}.vscode-marketplace;
in {
  extensions =
    (with fromNixpkgs; [
      #~@ Nix
      bbenoist.nix
      brettm12345.nixfmt-vscode
      jeff-hykin.better-nix-syntax
      jnoortheen.nix-ide
      mkhl.direnv
      kamadorueda.alejandra

      #~@ Git
      codezombiech.gitignore
      donjayamanne.githistory
      mhutchie.git-graph
      waderyan.gitblame

      #~@ AI
      github.copilot
      github.copilot-chat

      #~@ Shell
      mkhl.shfmt
      timonwong.shellcheck
      foxundermoon.shell-format

      #~@ Rust
      rust-lang.rust-analyzer
      vadimcn.vscode-lldb
      tamasfe.even-better-toml
      fill-labs.dependi

      #~@ Web
      bradlc.vscode-tailwindcss
      denoland.vscode-deno
      esbenp.prettier-vscode
      charliermarsh.ruff

      #~@ Language Support
      ms-vscode.powershell
      myriad-dreamin.tinymist
      thenuprojectcontributors.vscode-nushell-lang
      redhat.vscode-yaml
      davidanson.vscode-markdownlint
      mechatroner.rainbow-csv
      yzane.markdown-pdf
      yzhang.markdown-all-in-one

      #~@ Python
      ms-python.python
      ms-python.debugpy
      ms-python.vscode-pylance

      #~@ Docker
      ms-azuretools.vscode-docker

      #~@ Themes
      catppuccin.catppuccin-vsc
      uloco.theme-bluloco-dark
      uloco.theme-bluloco-light
      dracula-theme.theme-dracula
      mvllow.rose-pine

      #~@ Icons
      pkief.material-icon-theme
      pkief.material-product-icons

      #~@ Visual
      usernamehw.errorlens
      oderwat.indent-rainbow
      kamikillerto.vscode-colorize
      naumovs.color-highlight
      ibm.output-colorizer
      iliazeus.vscode-ansi
      spywhere.guides

      #~@ Utilities
      tyriar.sort-lines
      dotenv.dotenv-vscode
      editorconfig.editorconfig
      natqe.reload
      gruntfuggly.todo-tree
      formulahendry.code-runner
      hbenl.vscode-test-explorer
      jebbs.plantuml
      ritwickdey.liveserver
      tomoki1207.pdf
      wix.vscode-import-cost
      smcpeak.default-keys-windows
      tekumara.typos-vscode
      streetsidesoftware.code-spell-checker
      visualjj.visualjj
      wmaurer.change-case
      joshmu.periscope
      nhoizey.gremlins
      irongeek.vscode-env
      jgclark.vscode-todo-highlight
      ban.spellright
      tailscale.vscode-tailscale
      vitaliymaz.vscode-svg-previewer
      bodil.file-browser
      iciclesoft.workspacesort
      moshfeu.compare-folders
    ])
    ++ (with fromMarket; [
      #~@ Theme & UI
      allemandinstable.colorful-comments-refreshed
      brandonkirbyson.vscode-animations
      subframe7536.custom-ui-style
      be5invis.vscode-custom-css
      illixion.vscode-vibrancy-continued
      elanandkumar.el-vsc-product-icon-theme

      #~@ Visual
      lbragile.line-width-indicator
      bierner.markdown-mermaid
      bierner.github-markdown-preview
      emilast.logfilehighlighter

      #~@ AI
      codeium.codeium

      #~@ Language Support
      bluebrown.yamlfmt
      lkrms.inifmt
      nefrob.vscode-just-syntax
      kdl-org.kdl
      jjk.jjk
      hverlin.mise-vscode
      yy0931.gitconfig-lsp

      #~@ Database
      mtxr.sqltools
      mtxr.sqltools-driver-sqlite

      #~@ Utilities
      rebornix.toggle
      dakara.transformer
      jeff-hykin.better-shellscript-syntax
    ]);
}
