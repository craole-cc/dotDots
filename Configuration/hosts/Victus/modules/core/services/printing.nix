{
  host,
  lib,
  ...
}: {
  services.printing.enable = lib.elem "printing" host.functionalities;
}
