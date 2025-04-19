#!/usr/bin/env nu

# Define a function to watch and execute commands in different shells
def main [
    # The file to watch and execute, or the directory to watch for changes
    --file (-f): string
    # The command to execute directly (alternative to --file)
    --cmd (-c): string
    # The shell to use for execution
    --shell (-s): string = "C:/Program Files/Git/bin/bash.exe"
    # Arguments to pass to the shell
    --args (-a): string = "-i -l -c"
] {
    # Validate that either file or cmd is provided
    if ($file == null and $cmd == null) {
        print "Error: You must provide either --file or --cmd"
        exit 1
    }

    # Determine the execution command based on input
    let execution_cmd = if ($file != null) {
        let expanded_path = ($file | path expand)
        if ($shell =~ "powershell") {
            $"& $shell $args '& $expanded_path'"
        } else {
            $"$shell $args \"source $expanded_path\""
        }
    } else {
        $"$shell $args \"$cmd\""
    }

    # Determine what to watch based on input
    let watch_path = if ($file != null) {
        # If file is provided, watch that file
          $file
    } else {
        # If only cmd is provided, watch the current directory
        "."
    }

    # Print what we're doing
    print $"Watching ($watch_path) and executing: ($execution_cmd)"

    # Set up the watch command
    watch $watch_path {||
        print "\n[Executing command after change detected]"
        nu -c $execution_cmd
    }
}
