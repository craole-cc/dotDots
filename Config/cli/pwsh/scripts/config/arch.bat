@echo off

wsl.exe --distribution Arch ^
  cd ~ ;^
  fm6000 --random ;^
  exa --icons --all ;^
  zsh ;^


  @REM sudo pacman -Syyu --noconfirm; ^
  @REM cm() {cd /mnt/"$1"} ;^
  @REM alias dc='/mnt/c' de='/mnt/e' df='/mnt/f' ;^