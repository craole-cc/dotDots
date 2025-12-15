{ Lib, ... }:
{
  imports = [
    (Lib.programPerPolicy {
      name = "obs-studio";
      policy = "dev";
      autoImportPath = ./.;
    })
  ];
}
