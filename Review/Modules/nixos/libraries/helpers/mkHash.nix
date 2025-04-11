{
  num ? 8,
  string,
}:
let
  inherit (builtins) hashString substring;
in
substring 0 num (hashString "md5" string)
