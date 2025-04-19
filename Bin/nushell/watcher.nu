def to_bash_path [win_path: string] {
    $win_path
    | str replace -a '\\' '/'
    | str replace -a 'C:' '/c'
}

def main [
    --file: path,
    --cmd: string = "",
    --shell: string = "C:/Program Files/Git/bin/bash.exe"
] {
    let shell_path = $shell
    let file_to_watch = $file
    let shell_name = (echo $shell_path | str downcase)
    let command = if $cmd != "" { $cmd } else {
        if $shell_name =~ "bash" {
            let bash_path = (to_bash_path $file_to_watch)
            $"source \"$bash_path\""
        } else {
            $"source \"$file_to_watch\""
        }
    }
    let shell_args = if $shell_name =~ "bash" {
        [ "-i" "-l" "-c" $command ]
    } else if $shell_name =~ "powershell" {
        [ "-NoProfile" "-Command" $command ]
    } else if $shell_name =~ "fish" {
        [ "-c" $command ]
    } else if $shell_name =~ "zsh" {
        [ "-c" $command ]
    } else {
        [ "-c" $command ]
    }
    watch $file_to_watch {||
        ^$shell_path ...$shell_args
    }
}
