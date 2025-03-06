{
  num ? 8,
  string,
}:
let
  inherit (builtins) hashString substring;
  hash = substring 0 num (hashString "md5" string);
in
{
  inherit hash;
}
