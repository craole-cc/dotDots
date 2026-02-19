#!/usr/bin/env nu

def main [
    --file (-f): string
    --cmd (-c): string
    --shell (-s): string = "C:/Program Files/Git/bin/bash.exe"
    --args (-a): string = "-i -l -c"
]
{
if ($file ==nulland$cmd ==null){print "Error: You must provide either --file or --cmd"
exit 1
}let execution_cmd = 
if ($file !=null){let expanded_path = ($file | path expand
)
if ($shell =~"powershell"){$"& $shell $args '& $expanded_path'"}else
{$"$shell $args \"source $expanded_path\""}}else
{$"$shell $args \"$cmd\""}let watch_path = 
if ($file !=null){$file }else
{"."}print $"Watching ($watch_path ) and executing: ($execution_cmd )"watch $watch_path { ||
        print "\n[Executing command after change detected]"
        nu -c $execution_cmd
    }
}
