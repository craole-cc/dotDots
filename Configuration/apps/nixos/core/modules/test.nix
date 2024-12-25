{ specialArgs }:
let
  inherit (specialArgs.host) applications;
in
{
  _module.args.test = {
    inherit applications;
    allowHomeManager = applications.home-manager.enable or false;
  };

}
