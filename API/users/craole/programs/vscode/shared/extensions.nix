{ pkgs, ... }:
{
  programs.vscode = {
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      # Nix
      bbenoist.nix
      brettm12345.nixfmt-vscode
      jeff-hykin.better-nix-syntax
      jnoortheen.nix-ide
      mkhl.direnv

      # Git
      codezombiech.gitignore
      mhutchie.git-graph
      # eamodio.gitlens
      waderyan.gitblame

      # AI Assistants
      github.copilot
      github.copilot-chat
      # continue.continue

      # File Management
      bodil.file-browser
      iciclesoft.workspacesort
      moshfeu.compare-folders

      # Web Development
      bradlc.vscode-tailwindcss

      # Code Quality
      editorconfig.editorconfig
      mkhl.shfmt
      timonwong.shellcheck
      denoland.vscode-deno
      davidanson.vscode-markdownlint

      # Language Support
      ms-vscode.powershell
      rust-lang.rust-analyzer
      # techtheawesome.rust-yew
      vadimcn.vscode-lldb
      myriad-dreamin.tinymist
      tamasfe.even-better-toml
      thenuprojectcontributors.vscode-nushell-lang

      # Utilities
      tyriar.sort-lines
      wmaurer.change-case
      dotenv.dotenv-vscode
      joshmu.periscope
      natqe.reload
      ban.spellright
      streetsidesoftware.code-spell-checker
      nhoizey.gremlins
      tailscale.vscode-tailscale
      visualjj.visualjj
      vitaliymaz.vscode-svg-previewer
      yzhang.markdown-all-in-one
      yzane.markdown-pdf
      smcpeak.default-keys-windows

      # Themes & Icons
      pkief.material-icon-theme
      pkief.material-product-icons
      uloco.theme-bluloco-light

      # Visual Enhancements
      iliazeus.vscode-ansi
      jgclark.vscode-todo-highlight
      kamikillerto.vscode-colorize
      # naumovs.color-highlight
      mechatroner.rainbow-csv
      oderwat.indent-rainbow
      ibm.output-colorizer
      usernamehw.errorlens
      illixion.vscode-vibrancy-continued
      irongeek.vscode-env
    ];
  };
}
