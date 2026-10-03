#? Bluetooth hardware support.
#?
#? Membership is tested against the resolved functionality name list. This
#? previously read `lix.infrastructure.functionalities.bluetooth`, an argument
#? nothing ever provided, so `hardware.bluetooth.enable` never evaluated.
{
  context,
  lix,
  ...
}: let
  inherit (lix.lists) elem;

  functionalities = context.core.functionalities;
in {
  hardware.bluetooth = {
    enable = elem "bluetooth" functionalities;
    powerOnBoot = true;
  };
}