#? Home Manager wiring for this host's principals.
#?
#? `users.nix` declares the `home-manager.users` entry point; `user.nix` is
#? imported per-principal from it, so it is deliberately not listed here.
{imports = [./users.nix];}
