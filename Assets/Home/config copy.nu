# ===========================================================================
# DOTS Loader for Nushell - config.nu
# Loads the .dotsrc file found by env.nu
# $nu.config-path | path dirname
# ===========================================================================

#@ Load DOTS config if it was found by env.nu
if "DOTS_RC" in $env and ($env.DOTS_RC | path exists) {
    print $"Loading DOTS from: ($env.DOTS_RC)"

    #@ Load Nushell configuration directly from DOTS
    if "DOTS" in $env and ($env.DOTS | path exists) {
        #@ Execute the config files using nu -c with file paths
        let config_path = ($env.DOTS | path join "Configuration" "nushell" "config.nu")
        let env_path = ($env.DOTS | path join "Configuration" "nushell" "env.nu")

        #@ 
        if ($env_path | path exists) {nu -c $"source '($env_path)'"}
        if ($config_path | path exists) {nu -c $"source '($config_path)'"}

        print "✓ DOTS configuration loaded"
    }
}
