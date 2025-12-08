{ Lib, ... }:
{
  imports = [
    (Lib.programPerPolicy {
      name = "nh";
      policy = "dev";
      autoImportPath = ./.;
    })
  ];
}
