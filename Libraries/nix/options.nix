{_, ...}: {
  inherit
    (_.types.options)
    mkTrue
    mkFalse
    mkEnable
    mkIf
    mkMerge
    mkDefault
    mkForce
    mkOption
    ;

  inherit (_.types.checks) bool;
}
