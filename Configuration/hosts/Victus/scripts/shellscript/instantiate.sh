nix-instantiate --eval -E '(import <nixpkgs/nixos> { configuration = ./configuration.nix; }).config.users.users.craole' --strict
