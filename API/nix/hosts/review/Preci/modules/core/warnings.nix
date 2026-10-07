#? Surface what `context/` found, in the build log.
#?
#? `context` produces findings as data rather than calling `builtins.trace`,
#? because a trace is invisible in a `nixos-rebuild` log and cannot be collected.
#? Reading them here is what turns a silent degradation into something a user
#? sees -- a dropped package, a kernel variant below the ladder, a module that was
#? asked for and imported but never enabled.
#?
#? NixOS prints `config.warnings` during activation, so a finding reaches the
#? operator without this tree having to decide how loud to be.
#?
#? Every context record that reports findings is read, so adding one to
#? `context/` needs no change here -- the alternative is a list that has to be
#? kept in step with the modules that produce warnings.
{context, ...}: {
  warnings =
    (context.packages.warnings or [])
    ++ (context.modules.warnings or [])
    ++ (context.interface.warnings or [])
    ++ (context.capabilities.warnings or []);
}
