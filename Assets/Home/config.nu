# ===========================================================================
# DOTS Loader for Nushell - config.nu
# Loads the .dotsrc file found by env.nu
# $nu.config-path | path dirname
# ===========================================================================

#{ Load .dotsrc if it was found by env.nu
if "DOTS_RC" in $env and ($env.DOTS_RC | path exists) {
    print $"Loading DOTS from: ($env.DOTS_RC)"

    #{ Read the polyglot RC file
    let content = open $env.DOTS_RC

    #{ Extract Nushell section (lines starting with #nu)
    let nu_lines = $content
        | lines
        | where { |line| $line | str starts-with "#nu " }
        | each { |line| $line | str substring 4.. }
        | str join "; "

    if not ($nu_lines | is-empty) {
        print "Executing Nushell configuration..."
        #{ Execute the commands directly since they can't use source with variables
        try {
            nu -c $nu_lines
            print "✓ DOTS configuration loaded"
        } catch { |err|
            print $"Warning: Failed to execute Nushell section: ($err.msg)"
        }
    } else {
        print "No Nushell section found in .dotsrc"
    }
}
