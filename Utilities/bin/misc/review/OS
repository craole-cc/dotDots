#!/bin/sh

# . "$DOTS/Environment/Global/config/OS.sh"

__usage__() {
  echo "help"
}

__dir__() {
  fd . "$1" \
    --exclude review \
    --exclude archive \
    --exclude temp
}
remove_path() {
  echo ":$PATH:" | sed "s@:$1:@:@g;s@^:\(.*\):\$@\1@"
}
prepend_path() {
  if echo ":$PATH:" | grep -q ":$1:"; then echo "$PATH"; else echo "$1:$PATH"; fi
}
append_path() {
  if echo ":$PATH:" | grep -q ":$1:"; then echo "$PATH"; else echo "$PATH:$1"; fi
}

__addPATH__() {

  DIR="$1"
  if [ -d "$DIR" ]; then

    # Remove from PATH
    # Main Directory
    PATH=$(remove_path "$DIR")

    # Subdirectories
    for subDIR in $(__dir__ "$DIR"); do
      if [ -d "$subDIR" ]; then
        PATH=$(remove_path "$subDIR")
        # echo "$subDIR removed from PATH"
      fi
    done

    # Add to PATH
    case "$2" in
    perpend) # Add to the top of the list
      # Main Directory
      # PATH="$DIR:$PATH"
      PATH=$(prepend_path "$DIR")

      # Subdirectories
      for subDIR in $(__dir__ "$DIR"); do
        [ -d "$subDIR" ] &&
          PATH=$(prepend_path "$subDIR")
      done

      ;;
    *) # Add to the end of the list [default]

      # Main Directory
      # PATH="$PATH:$DIR"
      PATH=$(append_path "$DIR")

      # Subdirectories
      for subDIR in $(__dir__ "$DIR"); do
        [ -d "$subDIR" ] &&
          PATH=$(append_path "$subDIR")
      done
      ;;
    esac
  fi
}

__rmPATH__() {
  DIR="$1" &&
    if [ -d "$DIR" ]; then

      PATH=${PATH//":$DIR:"/":"} # delete any instances in the middle
      PATH=${PATH/#"$DIR:"/}     # delete any instance at the beginning
      PATH=${PATH/%":$DIR"/}     # delete any instance in the at the end
      echo "$DIR removed"

      for subDIR in $(__dir__ "$DIR"); do
        if [ -d "$subDIR" ]; then
          PATH=${PATH//":$subDIR:"/":"} # delete any instances in the middle
          PATH=${PATH/#"$subDIR:"/}     # delete any instance at the beginning
          PATH=${PATH/%":$subDIR"/}     # delete any instance in the at the end
          echo "$subDIR removed"
        fi
      done

    fi
}

__listPATH__() {
  echo "|------------------->> PATH <<-------------------|"
  printf %s\\n "$PATH" |
    awk -v RS=: '!($0 in a) {
    a[$0];
    printf("%s%s", length(a) > 1 ? ":" : "", $0)
    }' |
    tr ":" "\n"
}

__source__() {
  for SOURCE in $(__dir__ "$1"); do
    if [ -f "$SOURCE" ]; then
      # chmod 755 "$1" &&
      # . "$1" &&
      echo "Activated $SOURCE"
    fi
  done
}

__env__() {
  for SOURCE in $(
    __dir__ "$1"
  ); do
    if [ -d "$SOURCE" ]; then
      __pendP__ "$SOURCE"
    else
      # echo "FILE $SOURCE"
      __src__ "$SOURCE"
    fi
  done
}

ENVman() {
  options=$(getopt -l \
    "help,add:,path,append:,perpend:,source:,extract:,delete:,fd:" -o "hA:Pa:p:s:x:d:D" -a -- "$@")

  eval set -- "$options"

  while true; do
    case $1 in
    -P | --path)
      __listPATH__
      ;;
    -a | --append)
      shift

      __addPATH__ "$1"
      ;;
    -p | --perpend)
      shift
      __addPATH__ "$1" perpend
      ;;
    -s | --source)
      shift
      __source__ "$1"
      ;;
    -x | --extract)
      shift
      __extract__ "$1"
      ;;
    -d | --delete)
      shift
      __dir__ "$1"
      ;;
    -D | --fd)
      shift
      __dir__ "$1"
      ;;
    --)
      shift
      break
      ;;
    -h | --help)
      __usage__
      exit 0
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
    esac
    shift
  done
}
