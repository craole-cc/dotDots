[#](#) Apps

## [Rustup](https://reposhub.com/rust/development-tools/rust-lang-rustup.html)

  Toolchain installer for The Rust Programming Language, Rust programs and Cargo plugins

  ``` #! /bin/sh
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
  rustup toolchain install nightly --allow-downgrade --profile minimal --component clippy
  rustup default nightly
  rustup update
  ```

---

## [Paru](https://github.com/morganamilo/paru)

 Pacman wrapping AUR helper written in Rust.

  ``` #! /bin/sh
  sudo pacman -S --needed base-devel
  rm -rf ~/Downloads/Apps/paru
  git clone https://aur.archlinux.org/paru.git ~/Downloads/Apps/paru
  cd ~/Downloads/Apps/paru
  makepkg -si
  ```

---

## [Eww (ElKowar's Wacky Widgets)](https://elkowar.github.io/eww/main/)

  Widgeting system made in Rust.

  ``` #! /bin/sh
  dir="~/Downloads/Apps/eww"
  git clone https://github.com/elkowar/eww ~/Downloads/Apps/eww
  cd ~/Downloads/Apps/eww
  cargo build --release
  cd target/release
  chmod +x ./eww
  ./eww daemon
  ```

---

## [Has](https://github.com/kdabir/has)

  Checks presence of various command line tools and their versions on the path.

  ``` #! /bin/sh
  rm -rf ~/Downloads/Apps/has
  git clone https://github.com/kdabir/has.git ~/Downloads/Apps/has
  cd ~/Downloads/Apps/has
  make PREFIX=$HOME/.local install
  ```

---

## [exa](https://the.exa.website/)

  Improved file lister.

  ``` #! /bin/sh
  sudo pacman -S exa
  ```

  | Alias | Command | Description |
  | --- | --- | --- |
  | exa | exa --icons --color=always | Grid (icons, color) |
  | ls | exa --group-directories-first | Group by folder |
  | la | ls -a                | Grid |
  | ll | ls -al               | List |
  | lt | ls -aT               | Tree |
  | lss | exa -al -s=size     | Sort by size |
  | lsn | exa -al -s=newest   | Sort by date |
  | lso | exa -al -s=oldest   | Sort by date reverse |

---

## [Broot](https://github.com/Canop/broot)

  A better way to navigate directories

  ``` #! /bin/sh
  cargo install broot
  ```

  | Alias | Command | Description |
  | --- | --- | --- |
  | exa | exa --icons --color=always | Grid (icons, color) |
  | ls | exa --group-directories-first | Group by folder |
  | la | ls -a                | Grid |
  | ll | ls -al               | List |
  | lt | ls -aT               | Tree |
  | lss | exa -al -s=size     | Sort by size |
  | lsn | exa -al -s=newest   | Sort by date |
  | lso | exa -al -s=oldest   | Sort by date reverse |

---

## [ShellCheck](https://github.com/koalaman/shellcheck)

  Finds bugs in your shell scripts.

  ``` #! /bin/sh
  paru shellcheck-bin
  ```

---

## [expac](https://github.com/falconindy/expac)

  Data extraction tool for alpm databases, eg. pacman.

  ``` #! /bin/sh
  sudo pacman -S expac
  ```

---

## [Alacritty](https://github.com/alacritty/alacritty)

  A fast, cross-platform, OpenGL terminal emulator.

  ``` #! /bin/sh
  paru alacritty-ligatures-git
  ```

---

## [ripgrep](https://github.com/BurntSushi/ripgrep)

  Line-oriented search tool alternative to grep.

  ``` #! /bin/sh
  sudo pacman -S ripgrep
  ```

 ``` #! /bin/sh
  DIR="~/Downloads/Apps"
  ls $DIR
  git clone https://github.com/elkowar/eww $dir
  <!-- cd $dir -->
  ```
