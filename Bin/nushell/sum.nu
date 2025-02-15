def main [...numbers: int] {
    if ($numbers | is-empty) {
        help main | print -e
        exit 1
    }

    print ($numbers | math sum)
}
