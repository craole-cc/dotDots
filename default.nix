{
  lib ? import <nixpkgs/lib>,
  src ? ./.,
  ...
}: let
  inherit (import ./Libraries {inherit lib src;}) lix;
  inherit (import ./API {inherit lix;}) hosts users;

  repl = import ./Packages/cli/repl {inherit lib src lix hosts users;};
in {
  inherit lix users hosts repl;
}
