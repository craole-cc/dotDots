#!/bin/sh

nix repl --expr 'builtins.getFlake ".#";'
echo ":lf .#" | nix repl --expr 'builtins.getFlake ".#";'
