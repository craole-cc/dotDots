# PathOf

The absolute script normalizes a given target path by resolving symbolic links and removing redundant elements such as '.' and '..'.

## Usage

```sh
PathOf [OPTIONS] <target_path>
```

## Options

```sh
-h, --help               Display this help message and exit.
-v, --version            Display the version number and exit.
-q, --quiet              Only display the absolute path.
-d, --verbose [LEVEL]    Display additional information. Possible levels: debug, info (default), quiet.
```

## Arguments

```sh
<target_path>            The path to normalize.
```

## Examples

```sh
$ PathOf ~/../../usr/bin
/usr/bin

$ PathOf /usr/local/bin/../lib
/usr/local/lib

$ PathOf /var/log/../lib
/var/lib

$ PathOf /var//log/syslog
Invalid path: /var//log/syslog
```

## Dependencies

The script uses [`realpath`](https://www.gnu.org/software/coreutils/manual/html_node/realpath-invocation.html#realpath-invocation) if available, which is a part of the coreutils package. If realpath is not available, the script falls back to pure POSIX utilities implementation.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
