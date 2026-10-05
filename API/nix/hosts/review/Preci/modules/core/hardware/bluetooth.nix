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
  #? `names` on this record is a shape-reading function, not a list;
  #? `.resolved` is the name list membership is tested against.
  functionalities = context.functionalities.resolved;
  inherit (lix.lists) elem;
in {
  hardware.bluetooth = {
    enable = elem "bluetooth" functionalities;
    powerOnBoot = true;
  };
}