#? Per-principal Home Manager programs.
#?
#? One file per program, so each can be read, changed or dropped on its own.
#? This file only lists them; it configures nothing itself. Imported per
#? principal from `modules/home/default.nix`, so every file here is evaluated
#? inside `home-manager.users.<name>`.
{
  # imports = [./git.nix];
}
