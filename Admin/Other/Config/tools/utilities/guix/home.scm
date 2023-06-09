;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules 
  (gnu home)
  (gnu packages)
  (gnu services)
  (guix gexp)
  (gnu home services shells)
)

(home-environment
  ;; Below is the list of packages that will show up in your
  ;; Home profile, under ~/.guix-home/profile.
  (packages
    (specifications->packages 
      (list
        ;;@@@ WINDOW/DESKTOP MANAGEMENT
          ;;||| DE
            "lxqt"

          ;;||| WM
            "qtile"
            "emacs-exwm"
            "berry"
            "sway"
          
          ;;||| WIDGET/BAR
            "waybar"
            "polybar"

        ;;@@@ EYE CANDY
          ;;||| GTK THEME
            "orchis-theme"
            "matcha-theme"
            "arc-icon-theme"

          ;;||| ICON THEME
            "breeze-icons"
            "guix-icons"
            "moka-icon-theme"

        ;;@@@ FONTS
          ;;||| ICON
            "font-google-material-design-icons"
            "font-awesome"
            "font-google-noto"

          ;;||| MONOSPACE
            "font-dejavu"
            "font-fira-code"
            "font-hack"
            "font-iosevka"
            "font-iosevka-aile"
            "font-jetbrains-mono"
            "font-victor-mono"
          
          ;;||| MONOSPACE
            "font-ghostscript"
            "font-gnu-freefont"
            "font-abattis-cantarell"

        ;;@@@ SYSTEM UTILITIES
          "xdg-desktop-portal"
          "rust-directories"
          "syncthing-gtk"
          "udiskie"
          "qjackctl"
          "bluez"
          "dunst"
          "volumeicon"
          "thunar-volman"
          "ffmpeg"
          "xfce4-places-plugin"
          "emacs-desktop-environment"
          "nm-tray"
          "pavucontrol"

        ;;@@@ TERM UTILITIES
          ;;||| FILE MANAGEMENT
            "fd"
            "ripgrep"
            "bat"
            "feh"
            "rbw"
          
          ;;||| FETCH
            "wget"
            "curl"
            "git"

          ;;||| SYS INFO
            "htop"
            "bpytop"
            "neofetch"
            "ufetch"

          ;;||| SHELL
            "nushell"
            "zsh"

        ;;@@@ APPS
          ;;||| PACKAGE MANAGEMENT
            "flatpak"

          ;;||| LAUNCHER
            "rofi"
            "dmenu"
            ;; "fuzzel"
            "wofi"

          ;;||| MEDIA
            "mpv"
            "strawberry"
            "qbittorrent"

          ;;||| TERMINAL EMULATOR
            "kitty"
            "alacritty"
            "xterm"
            "foot"

          ;;||| BROWSER
          "icecat"
          "qutebrowser"
          "vimb"

          ;;||| CREATIVE
          "darktable"
          "inkscape"
          "gimp"

        ;;@@@ DEVELOPMENT TOOLS
          ;;||| EDITOR
            "neovim"
            "emacs"
            "emacs-guix"
            "emacs-rust-mode"
            "emacs-haskell-mode"
            "emacs-spacegray-theme"
            "emacs-doom-themes"
            "emacs-general"
            "emacs-which-key"
            "emacs-undo-tree"
            "emacs-evil-collection"
            "emacs-evil"
            "emacs-no-littering"
            "emacs-use-package"

          ;;||| RUST
            "rust"
            "rust-cargo"

          ;;||| PYTHON
            "python"

          ;;||| HASKELL
            "ghc"
            "gcc-toolchain"
            "hoogle"
            "hlint"

          ;;||| LISP
            "sbcl"
            "sbcl-slynk"
      )
    )
  )

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
    (list
      (service home-bash-service-type
        (home-bash-configuration
          (aliases '(
			      ("GuixSystem" . "guix pull; sudo guix system reconfigure /store/Dotfiles/Config/tools/utilities/guix/system.scm")
			      ("GuixHome" . "guix home reconfigure /store/Dotfiles/Config/tools/utilities/guix/home.scm")
			      ;; ("GuixHome" . "guix home reconfigure ~/.config/guix/home.scm")
          ))
          ;; (bashrc (list (local-file "~/.bashrc" "bashrc")))
          ;; (bash-profile (list (local-file "~/.bash_profile" "bash_profile")))
        )
      )
    )
  )
)
