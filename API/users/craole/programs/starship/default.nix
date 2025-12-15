{ Lib, ... }:
{
  imports = [
    (Lib.programPerPolicy {
      name = "starship";
      policy = "dev";
      autoImportPath = ./.;
    })
  ];
}
