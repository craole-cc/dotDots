{ Lib, ... }:
{
  imports = [
    (Lib.servicePerPolicy {
      name = "bat-signal";
      policy = "dev";
      autoImportPath = ./.;
    })
  ];
}
