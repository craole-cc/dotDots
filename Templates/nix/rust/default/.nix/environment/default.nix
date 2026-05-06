{
  lib,
  inputs,
  pkgs,
  ...
}:
lib.shells.mkDevShells {inherit lib inputs pkgs;}
