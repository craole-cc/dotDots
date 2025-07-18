#!/bin/sh
# shellcheck disable=SC1078,SC1079,SC1083,SC2086

main() {

  #{ Set defaults
  set_defaults

  # listman --test && return

  #{ Parse arguments
  parse_arguments "$@"

  case "${environment}" in
  test)
    listman__test
    return 0
    ;;
  *)
    #{ Perform the requested action
    execute \
      --item "nix" \
      --base "validate_cmd" \
      --item "fd" \
      --item "cargo" \
      --list "${command_list}"
    return 0
    ;;
  esac

}

set_defaults() {
  #{ Initialize variables
  verbosity=2
  debug=""
  gen_date_or_count=0
  delimiter="$(printf '\003')"

  #{ Define the default  applications to collect garbage from
  garbage_list=""
  listman --include --list garbage_list --item nixos
  listman --include --list garbage_list --item home-manager

  #{ Define the default commands to to validate
  command_list=""
  listman --include --list command_list --item nix
  listman --include --list command_list --item nix-collect-garbage
  listman --include --list command_list --item nix-store
  listman --include --list command_list --item home-manager
  listman --include --list command_list --item fd
  listman --include --list command_list --item cargo
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --help)
      help
      return 0
      ;;
    -v | --version) ;;
    -Q | --quiet)
      verbosity=0
      ;;
    -E | --error)
      verbosity=1
      ;;
    -W | --warn)
      verbosity=2
      ;;
    -I | --info)
      verbosity=3
      ;;
    -D | --debug | --dry-run)
      debug=true
      environment="test"
      verbosity=4
      ;;
    -T | --trace)
      verbosity=5
      ;;
    -V*)
      verbosity="${1#-V}"
      if [ "$verbosity" ]; then
        verbosity="${#verbosity}"
      else
        verbosity=3
      fi
      ;;
    --verbose)
      if [ "$2" ]; then
        shift
        verbosity="$1"
      else
        verbosity=3
      fi
      ;;
    --nix)
      case "$2" in
      [0-9]*)
        shift
        gen_date_or_count="$1"
        ;;
      '' | *) ;;
      esac
      listman --include --list garbage_list --item "nix"
      listman --include --list garbage_list --item "home-manager"
      ;;
    --home* | --hm)
      case "$2" in
      [0-9]*)
        shift
        gen_date_or_count="$1"
        ;;
      '' | *) ;;
      esac

      listman --include --list garbage_list --item "home-manager"
      ;;
    *) ;;
    esac
    shift
  done

  [ -n "${debug}" ] && {
    printf "DEBUG: verbosity: %s\n" "${verbosity}"
    printf "DEBUG: gen_date_or_count: %s\n" "${gen_date_or_count}"
    printf "DEBUG: garbage_list: [%s]\n" "$(
      counter=0
      for item in ${garbage_list}; do
        [ "${counter:-0}" -eq 1 ]
        if [ "${counter:-0}" -eq 1 ]; then
          printf "%s" "${item}"
        else
          printf ", %s" "${item}"
        fi
      done
    )"
  }
}

listman() {

  listman__main() {
    #{ Set defaults
    unique_delimiter="${delimiter:-"$(printf '\037')"}"
    actual_delimiter=' '

    #{ Parse arguments
    listman__parse_arguments "$@"
  }

  listman__usage() {
    case "$1" in
    --list) printf "ERROR: A list variable name is required.\n" ;;
    --item) printf "ERROR: An item is required.\n" ;;
    --arg) printf "ERROR: An argument is required for '%s'.\n" "$2" ;;
    --var) printf "ERROR: Missing variable: '%s'.\n" "$2" ;;
    '') printf "ERROR: No options provided.\n" ;;
    *) printf "ERROR: Invalid option: '%s'.\n" "$1" ;;
    esac
  }

  listman__parse_arguments() {
    while [ "$#" -gt 0 ]; do
      case "$1" in
      --test) listman__test && return 0 ;;
      --include)
        [ "$2" ] || { listman__usage --arg "$1" && return 1; }
        shift
        while [ "$#" -gt 1 ]; do
          case "$1" in
          --list)
            if [ "$2" ]; then
              list_to_include="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --item)
            if [ "$2" ]; then
              item_to_include="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          esac
          shift
        done

        #{ Validate variables
        [ "$list_to_include" ] || { listman__usage --var "list" && return 1; }
        [ "$item_to_include" ] || { listman__usage --var "item" && return 1; }
        [ "$delimiter" ] || { listman__usage --var "delimiter" && return 1; }

        listman__include "$@"
        ;;
      --normalize)
        [ "$2" ] || { listman__usage --arg "$1" && return 1; }
        shift
        while [ "$#" -gt 1 ]; do
          case "$1" in
          --list)
            if [ "$2" ]; then
              list_to_normalize="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --delimiter)
            if [ "$2" ]; then
              actual_delimiter="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          *)
            [ "$list_to_normalize" ] || list_to_normalize="$1"
            ;;
          esac
          shift
        done

        #{ Validate variables
        [ "$list_to_normalize" ] || { listman__usage --var "list" && return 1; }
        [ "$actual_delimiter" ] || { listman__usage --var "delimiter" && return 1; }
        [ "$unique_delimiter" ] || { listman__usage --var "unique_delimiter" && return 1; }

        #{ Normalize the list
        listman__normalize "$list_to_normalize" "$actual_delimiter" "$unique_delimiter"
        ;;
      --parse)
        [ "$2" ] || { listman__usage --arg "$1" && return 1; }
        shift

        #{ Parse arguments
        parse__list=""
        parse__operation="print"
        parse__command=""

        while [ "$#" -gt 1 ]; do
          case "$1" in
          --list)
            if [ "$2" ]; then
              parse__list="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --delimiter)
            if [ "$2" ]; then
              actual_delimiter="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --border | --outline | --frame)
            if [ "$2" ]; then
              parse__border="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --seperator)
            if [ "$2" ]; then
              parse__seperator="$2"
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --operation)
            if [ "$2" ]; then
              parse__operation="$2"
              case "$2" in
              comma) comma=true ;;
              square) square=true ;;
              count) count=true ;;
              print) print=true ;;
              index | number) index=true ;;
              exec) exec=true ;;
              *) ;;
              esac

              # listman --include --list parse__operation --item "$2"
              # if [ "$parse__operation" ]; then
              #     parse__operation="$(printf '%s%s%s' "$parse__operation" " " "$2")"
              #     # parse__operation="$parse__operation $2"
              # else
              #     parse__operation="$2"
              # fi
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          --command)
            if [ "$2" ]; then
              parse__command="$2"
              parse__operation="exec"
              exec=true
              # if [ "$parse__operation" ]; then
              #     parse__operation="$(printf '%s%s%s' "$parse__operation" " " "exec")"
              #     # parse__operation="$(printf '%s%s%s' "$parse__operation" "$unique_delimiter" "exec")"
              # else
              #     parse__operation="exec"
              # fi
            else
              listman__usage --arg "$1" && return 1
            fi
            ;;
          esac
          shift

        done
        #{ Execute the parse function
        listman__parse "$@"
        ;;
      esac
      shift

    done
  }

  listman__include() {
    include__usage() {
      case "$1" in
      --list) printf "ERROR: A list variable name is required.\n" ;;
      --item) printf "ERROR: An item is required.\n" ;;
      esac
      printf "\nUSAGE:  listman --include --list <VARIABLE> --item <ITEM>\n"
      printf "    VARIABLE    Variable for the list of items\n"
      printf "    ITEM        Item to include in the list\n"
    }

    # eval "case \"\${$list_to_include}\" in
    #     *\"$item_to_include\"*) ;;
    #     *) $list_to_include=\"\$(printf '%s%s%s' \"\${$list_to_include}\" \"$item_to_include\")\" ;;
    # esac"
    #{ Check if the item is already in the list
    eval "case \"\${$list_to_include}\" in
            *\"$delimiter$item_to_include$delimiter\"*) ;;  # Item already exists, do nothing
            *)
                # Add the item to the list
                if [ -z \"\${$list_to_include}\" ]; then
                    #{ List is empty, add the item without a delimiter
                    eval "$list_to_include=\"$item_to_include\""
                else
                    #{ List is not empty, append the item with a delimiter
                    eval "$list_to_include=\"\${$list_to_include}${delimiter}${item_to_include}\""
                fi
                ;;
        esac"
  }

  listman__normalize() {
    #DOC Normalize a list by replacing multiple occurrences of the specified delimiter
    #DOC with a single global delimiter or a default delimiter. This function takes a
    #DOC required list and current delimiter, with an optional global delimiter, and
    #DOC returns a string with normalized delimiters.
    #DOC
    #DOC Arguments:
    #DOC   $1 - The list to normalize.
    #DOC   $2 - (Optional) The current delimiter to replace in the list. Defaults to space.
    #DOC   $3 - (Optional) The global delimiter to replace the current delimiter with.
    #DOC        Defaults to a pre-configured delimiter.
    #DOC
    #DOC Returns:
    #DOC   A string with normalized delimiters, where occurrences of the current delimiter
    #DOC   are replaced with the global delimiter, and excessive whitespace is removed.

    #{ Define variables
    list="$1"
    current_delim="${2-" "}"
    global_delim="${3-"$(printf '\037')"}" # \037 is octal for \x1F

    #{ First normalize the delimiters and whitespace
    normalized=$(
      printf '%s' "${list}" |
        tr -s "${current_delim}" "${global_delim}" |
        tr -s '[:space:]'
    )

    #{ Trim leading and trailing delimiters and whitespace
    normalized=$(
      printf '%s' "${normalized}" |
        sed -e "s/^[${global_delim}[:space:]]*//g" \
          -e "s/[${global_delim}[:space:]]*$//g"
    )

    #{ Return the normalized list
    printf '%s' "${normalized}"
  }

  listman__parse() {
    #DOC Parse a list into individual items and optionally perform operations on them.
    #DOC
    #DOC Arguments:
    #DOC   --list        The list to parse
    #DOC   --delimiter   (Optional) The delimiter separating items. Defaults to space.
    #DOC   --operation   (Optional) Operation to perform on each item:
    #DOC                 - count: Count total items
    #DOC                 - print: Print each item on a new line
    #DOC                 - index: Print items with their index
    #DOC                 - exec: Execute a command for each item (requires --command)
    #DOC   --command    (Optional) Command to execute for each item. Use {} as placeholder.
    #DOC
    #DOC Returns:
    #DOC   Output depends on the operation specified.

    #{ Initialize variables
    parse__list="${parse__list:-"$1"}"
    parse__operation="${parse__operation:-"$2"}"
    actual_delimiter="${actual_delimiter:-"$3"}"
    parse__command="${parse__command:-"$4"}"

    #{ Validate required arguments
    if [ "$parse__list" ]; then
      parse__list=$(
        listman --normalize \
          --list "$parse__list" \
          --delimiter "$actual_delimiter" |
          tr "$unique_delimiter" ' '
      )
    else
      listman__usage --var "list" && return 1
    fi

    #{ Handle empty list
    [ -z "$parse__list" ] && {
      [ "$parse__operation" = "count" ] && printf "0\n"
      return 0
    }

    case "$parse__operation" in
    number | index)
      counter=0
      result="$(
        for item in $parse__list; do
          counter=$((counter + 1))
          printf '%d. %s\n' "$counter" "$item"
        done
      )"
      ;;
    count)
      counter=0
      result="$(
        for item in $parse__list; do
          counter=$((counter + 1))
        done
        printf '%d' "$counter"
      )"
      ;;
    exec)
      counter=0
      result="$(
        for item in $parse__list; do
          eval "$(printf '%s' "$parse__command" | sed "s|{}|$item|g")"
        done
      )"
      ;;
    esac
    printf "%s" "$result"

    case "$parse__seperator" in
    comma)
      first=true=
      result="$(
        for item in $parse__list; do
          [ "$item" ] || continue
          if [ "$first" ]; then
            unset first
            printf '%s' "$item"
          else
            printf ', %s' "$item"
          fi
        done
      )"
      ;;
    space)
      first=true
      result="$(
        for item in $parse__list; do
          [ "$item" ] || continue
          if [ "$first" ]; then
            unset first
            printf '%s' "$item"
          else
            printf ' %s' "$item"
          fi
        done
      )"
      ;;
    newline)
      first=true
      result="$(
        for item in $parse__list; do
          [ "$item" ] || continue
          if [ "$first" ]; then
            unset first
            printf '%s' "$item"
          else
            printf '\n%s' "$item"
          fi
        done
      )"
      ;;
    esac

    case "$parse__border" in
    square*) result="[$result]" ;;
    bracket*) result="($result)" ;;
    curly*) result="{$result}" ;;
    esac

    #{ Return the parsed list
    printf '%s' "$result"

  }

  listman__test() {
    test_list="apple banana cherry durian egg"
    test_list_space="one two fd three four five six"
    test_list_newline="
                pop
            lol
                flow
        "
    display_line="---------------------------------------------"
    printf '%s\nACTUAL LIST\n%s\n\nPARSED LIST\n%s\n%s' \
      "$display_line" \
      "$test_list" \
      "$(listman --parse --list "$test_list" --operation exec --command "echo pop {}")" \
      "$display_line"
    printf '\nACTUAL LIST\n%s\n\nPARSED LIST\n%s\n%s' \
      "$test_list_space" \
      "$(listman --parse --list "$test_list_space" --command "command -v {}" --operation exec)" \
      "$display_line"
    printf '\nACTUAL LIST\n%s\n\nPARSED LIST\n%s\n%s' \
      "$test_list_newline" \
      "$(listman --parse --list "$test_list_newline" --command "echo free {} money")" \
      "$display_line"
    printf '\nACTUAL LIST\n%s\n\nPARSED LIST\n%s\n%s' \
      "$(
        listman --parse \
          --list "$command_list" \
          --seperator "comma" \
          --frame curly \
          --command "printf "[%s]" {}"
        # --operation "comma-square"
      )" \
      "$(
        listman --parse \
          --list "$command_list" \
          --seperator "comma" \
          --frame curly \
          --command "command -v {}"
      )" "$display_line"
  }

  listman__main "$@"
}

execute() {
  #DOC Execute a command for a specified item from a list. The command can be
  #DOC customized by specifying optional commands to be executed before and after
  #DOC the main command. The function parses arguments to set list, item, base
  #DOC command, and optional commands. It checks if the item exists in the list and
  #DOC constructs and executes the full command sequence accordingly.
  #DOC
  #DOC Options:
  #DOC   -l, --list       List containing items, separated by space or newline.
  #DOC   -i, --item       Item to execute commands on.
  #DOC   -c, --base       Base command to execute for the item (can be repeated).
  #DOC   -b, --before     Optional command to execute before the main command.
  #DOC   -a, --after      Optional command to execute after the main command.
  #DOC
  #DOC Usage:
  #DOC   execute --list <LIST> --item <ITEM> --base <BASE_COMMAND>
  #DOC           [--before <OPT_BEFORE_ITEM>] [--after <OPT_AFTER_ITEM>]
  #DOC
  #DOC Example:
  #DOC   my_list="item1 item2 item3"
  #DOC   execute --list "$my_list" --item "item2" --base "echo Processing"
  #DOC           --before "echo Starting" --after "echo Finished"
  #DOC
  #DOC Help:
  #DOC   Use execute_cmd__usage for detailed usage instructions and error messages.

  execute__usage() {
    case "$1" in
    --list) printf "ERROR: A list variable name is required.\n" ;;
    --item) printf "ERROR: An item is required.\n" ;;
    --arg) printf "ERROR: An argument is required for '%s'.\n" "$2" ;;
    --delim) printf "ERROR: A delimiter is required for '%s'.\n" "$2" ;;
    '') printf "ERROR: No options provided.\n" ;;
    *) printf "ERROR: Invalid option: '%s'.\n" "$1" ;;
    esac

    printf "\nUSAGE: execute %s %s\n" \
      "[--list <LIST>] [--item <ITEM>] [--base <BASE_COMMAND>]" \
      "[--before <OPT_BEFORE_ITEM>] [--after <OPT_AFTER_ITEM>]"
    printf "  LIST                List containing items, seperated by space or newline\n"
    printf "  ITEM                Item to execute commands on\n"
    printf "  BASE_COMMAND        Command to execute for the item (can be repeated)\n"
    printf "  OPT_BEFORE_ITEM     Command to execute before the main command\n"
    printf "  OPT_AFTER_ITEM      Command to execute after the main command\n"
    printf "\nEXAMPLE:\n"
    printf "    my_list=\"item1 item2 item3\"\n"
    printf "    execute --list \"\$my_list\" --item \"item2\" --base \"echo Processing\" --before \"echo Starting\" --after \"echo Finished\"\n"

  }

  execute__parse_arguments() {
    #{ Initalize variables
    execute__delimiter=' '
    execute__list=
    execute__item=
    execute__base=
    execute__next=
    execute__last=

    #{ Parse arguments
    while [ "$#" -gt 0 ]; do
      case "$1" in
      -l | --list)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        execute__list="$1"
        ;;
      -i | --item)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        listman --include --list execute__item --item "$1"
        ;;
      -c | --base | --cmd)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        listman --include --list execute__base --item "$1"
        ;;
      -b | --before)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        listman --include --list execute__next --item "$1"
        ;;
      -a | --after)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        listman --include --list execute__last --item "$1"
        ;;
      -d | --delim*)
        [ "$2" ] || { execute__usage --arg "$1" && return 1; }
        shift
        execute__delimiter="$1"
        ;;
      esac
      shift
    done

    #{ Debug the arguments
    [ "$debug" ] && {
      printf "DEBUG: EXECUTE_CMD__ITEM: %s\n\n" "$execute__item"
      printf "DEBUG: EXECUTE_CMD__LIST: %s\n\n" "$execute__list"
      printf "DEBUG: EXECUTE_CMD__BASE: %s\n\n" "$execute__base"
      printf "DEBUG: EXECUTE_CMD__NEXT: %s\n\n" "$execute__next"
      printf "DEBUG: EXECUTE_CMD__LAST: %s\n\n" "$execute__last"
    }

    echo "-------------------------------------"
    echo "EXECUTE_CMD__ITEM: $execute__item"
    echo "EXECUTE_CMD__LIST: $execute__list"
    echo "EXECUTE_CMD__BASE: $execute__base"
    echo "EXECUTE_CMD__NEXT: $execute__next"
    echo "EXECUTE_CMD__LAST: $execute__last"
    echo "-------------------------------------"

    #{ Normalize arguments
    execute__item_normalized="$(listman --normalize --list "$execute__item" --delimiter "$execute__delimiter")"
    execute__list_normalized="$(listman --normalize --list "$execute__list" --delimiter "$execute__delimiter")"
    execute__base_normalized="$(listman --normalize --list "$execute__base" --delimiter "$execute__delimiter")"
    # execute__next_normalized="$(listman --normalize --list "$execute__next" --delimiter "$execute__delimiter")"
    # execute__last_normalized="$(listman --normalize --list "$execute__last" --delimiter "$execute__delimiter")"
    [ "$debug" ] && {
      printf "DEBUG: EXECUTE_CMD__ITEM_NORMALIZED: %s\n\n" "$execute__item_normalized"
      printf "DEBUG: EXECUTE_CMD__LIST_NORMALIZED: %s\n\n" "$execute__list_normalized"
      printf "DEBUG: EXECUTE_CMD__BASE_NORMALIZED: %s\n\n" "$execute__base_normalized"
      # printf "DEBUG: EXECUTE_CMD__NEXT_NORMALIZED: %s\n\n" "$execute__next_normalized"
      # printf "DEBUG: EXECUTE_CMD__LAST_NORMALIZED: %s\n\n" "$execute__last_normalized"
    }
  }

  execute__main() {
    execute__parse_arguments "$@"

    # execute__array="${execute__split}$(
    #     printf "%s" "$execute__list" |
    #         tr "$execute__delimiter" "$execute__split"
    # )${execute__split}"
    # execute__items="${execute__split}$(
    #     printf "%s" "$execute__item" |
    #         tr "$execute__delimiter" "$execute__split"
    # )${execute__split}"

    # source_item_num=0
    # for source_item in $execute__array; do
    #     [ "$source_item" = "$execute__split" ] && continue
    #     source_item_num=$((source_item_num + 1))

    #     target_item_num=0
    #     for target_item in $execute__items; do
    #         [ "$target_item" = "$execute__split" ] && continue
    #         target_item_num=$((target_item_num + 1))
    #         # echo "Target $target_item_num: $target_item"

    #         case "$source_item" in
    #         "$target_item")
    #             echo "Found source item in array: $source_item"
    #             break
    #             ;;
    #         esac
    #     done
    # done

    # # Normalize the list and items into a unique delimiter (ASCII unit separator: \x1F)
    # unique_delimiter=$(printf '\x1F')
    # normalized_list="$(echo "$execute__list" | tr "$execute__delimiter" "$unique_delimiter")"
    # normalized_items="$(echo "$execute__item" | tr "$execute__delimiter" "$unique_delimiter")"

    # # Loop through each item and check if it exists in the list
    # found_items=0
    # error_items=0
    # for item in $(echo "$normalized_items" | tr "$unique_delimiter" ' '); do
    #     case "$unique_delimiter$normalized_list$unique_delimiter" in
    #     *"$unique_delimiter$item$unique_delimiter"*)
    #         # Construct the full command
    #         execute__exec="$(
    #             printf '%s %s %s %s\n' \
    #                 "$execute__base" \
    #                 "$execute__next" \
    #                 "$item" \
    #                 "$execute__last"
    #         )"

    #         [ "$debug" ] && {
    #             printf "DEBUG: EXECUTE_CMD__EXEC: %s\n" "$execute__exec"
    #         }

    #         # Execute the command
    #         echo "OW: $execute__exec"
    #         found_items=$((found_items + 1))
    #         ;;
    #     *)
    #         # Item not found in the list
    #         { [ "$debug" ] || [ "${verbosity:-0}" -gt 3 ]; } || continue

    #         printf "Error: '%s' is not a member of [%s]\n" \
    #             "$item" \
    #             "$(echo "$execute__list" | tr "$execute__delimiter" ',')"
    #         error_items=$((error_items + 1))
    #         ;;
    #     esac
    # done

    return

    #{ Check if the item is in the list
    # case " $execute__list " in
    case $(seperate_by_space "$execute__list") in
    *" $execute__item "*)

      #{ Construct the full command
      execute__exec="$(
        seperate_by_space "$(
          printf "%s %s %s %s\n" \
            "$(seperate_by_space "$execute__base")" \
            "$(seperate_by_space "$execute__next")" \
            "$(seperate_by_space "$execute__item")" \
            "$(seperate_by_space "$execute__last")"
        )"
      )"

      #{ Debug print and skip execution if specified
      [ "$debug" ] && {
        printf "DEBUG: EXECUTE_CMD__EXEC: %s\n" "$execute__exec"
        return 0
      }

      #{ Execute the command
      eval "$execute__exec"
      ;;
    *)
      #{ Skip error messaging if debug and verbosity are disabled
      { [ "$debug" ] || [ "${verbosity:-0}" -gt 3 ]; } || return 1

      #{ Print error message
      if [ "$execute__list" ]; then
        printf "Error: '%s' is not a member of [%s]\n" \
          "$execute__item" \
          "$(echo "$execute__list" | tr ' ' ',')"
      else
        printf "Error: The list of items to execute is empty\n"
      fi

      return 1
      ;;
    esac

    # if
    #     printf '%s\n' "$execute__list" |
    #         grep --fixed-strings --line-regexp --quiet "$execute__item"
    # then
    #     execute__exec="$(
    #         seperate_by_space "$(
    #             printf "%s %s %s %s\n" \
    #                 "$(seperate_by_space "$execute__base")" \
    #                 "$(seperate_by_space "$execute__next")" \
    #                 "$(seperate_by_space "$execute__item")" \
    #                 "$(seperate_by_space "$execute__last")"
    #         )"
    #     )"

    #     [ "$debug" ] && {
    #         printf "DEBUG: EXECUTE_CMD__EXEC: %s\n" "$execute__exec"
    #         return 0
    #     }

    #     [ "$execute__exec" ] && eval "$execute__exec"
    # else
    #     { [ "$debug" ] || [ "${verbosity:-0}" -gt 3 ]; } || return

    #     if [ "$execute__list" ]; then
    #         printf "Error: '%s' is not a member of [%s]\n" "$execute__item" "$(
    #             counter=0
    #             for item in $execute__list; do
    #                 counter=$((counter + 1))
    #                 if [ "$counter" -eq 1 ]; then
    #                     printf "%s" "$item"
    #                     unset first_item
    #                 else
    #                     printf ", %s" "$item"
    #                 fi
    #             done
    #         )"
    #     else
    #         printf "Error: The list of items to execute is empty\n"
    #     fi

    #     return 1
    # fi
  }

  execute__main "$@"
}

seperate_by_space() {
  printf "%s" "$(
    printf "%s" "$1" |
      tr '\n' ' '
  )" | awk '{$1=$1};1'
}

convert_to_seconds() {
  value=$1
  unit=$2

  case "$unit" in
  #TODO: expr is antiquated. Consider rewriting this using $((..)), ${} or [[ ]].shellcheckSC2003
  h | hour | hours) expr "$value" \* 3600 ;;
  d | day | days) expr "$value" \* 86400 ;;
  w | week | weeks) expr "$value" \* 604800 ;;
  m | month | months) expr "$value" \* 2592000 ;; # 30 days
  y | year | years) expr "$value" \* 31536000 ;;
  *) printf "%s" "$value" ;;
  esac
}

validate_expiry_date() {
  _print_error() {
    #TODO: Improve the error handling with case options
    printf "ERROR: Invalid generations format. Must be:\n"
    printf "  - a number (e.g., '30')\n"
    printf "  - a number with unit (e.g., '30d', '24h', '4w', '2m', '1y')\n"
    printf "  - a number with space and unit (e.g., '30 days')\n"
    printf "  - a timestamp (e.g., '2024-01-21')\n"
  }

  #{ Check if empty
  if [ "$1" ]; then
    date_to_validate="$1"
  else
    printf "ERROR: Missing date to validate.\n"
    return 1
  fi

  #{ Extract first character to check if it's a number
  first_char=$(printf "%s" "$date_to_validate" | cut -c1)

  #{ Check if it starts with a number
  case "$first_char" in
  [0-9])
    #{ Check various formats
    case "$date_to_validate" in
    #{ If the first char is a number, check if it's pure number
    *[!0-9]*)
      #{ Contains non-digits, check for valid time formats
      case "$date_to_validate" in
      *[hdwmy])
        #{ Check if everything except last char is number
        without_unit=$(printf "%s" "$date_to_validate" | sed 's/[hdwmy]$//')
        case "$without_unit" in
        *[!0-9]*)
          _print_error
          return 1
          ;;
        esac
        ;;
      *" days" | *" day" | *" hours" | *" hour" | \
        *" weeks" | *" week" | *" months" | *" month" | \
        *" years" | *" year")
        #{ Check if everything before space is number
        num_part=$(printf "%s" "$date_to_validate" | cut -d' ' -f1)
        case "$num_part" in
        *[!0-9]*)
          _print_error
          return 1
          ;;
        esac
        ;;
      *)
        _print_error
        return 1
        ;;
      esac
      ;;
    esac
    ;;
  *)
    #{ Check if it's a valid date format YYYY-MM-DD
    case "$date_to_validate" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      if ! date -d "$date_to_validate" >/dev/null 2>&1; then
        printf "ERROR: Invalid date format. Use YYYY-MM-DD.\n"
        return 1
      fi
      ;;
    *)
      _print_error
      return 1
      ;;
    esac
    ;;
  esac
  return 0
}

validate_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "Command found: %s\n" "$1"
    return 0
  else
    if [ "${verbosity:-0}" -gt 3 ]; then
      printf "ERROR: '%s' is not installed or in PATH.\n" "$1"
    fi
    return 1
  fi
}

set_expiry_date() {
  #{ Parse arguments
  while [ "$#" -gt 0 ]; do
    case "$1" in
    --tool) tool="$2" ;;
    --date)
      [ "$2" ] && {
        date="$2"
        shift
      }
      ;;
    esac
    shift
  done

  #{ Validate arguments
  validate
  validate_generations "$date" || return 1

  #{ Set generations based on tool
  case "$tool" in
  nix)
    #{ Handle different formats
    case "$generations" in
    *[hdwmy])
      value=$(printf "%s" "$generations" | sed 's/[hdwmy]$//')
      unit=$(printf "%s" "$generations" | sed 's/.*\(.\)$/\1/')
      seconds=$(convert_to_seconds "$value" "$unit")
      cutoff_date=$(date -d "@$(expr "$(date +%s)" - $seconds)" +%Y-%m-%d)
      num_generations=$(nix-env --list-generations |
        awk -v cutoff="$cutoff_date" '$1 > cutoff {count++} END {print count}')
      ;;
    *" "*)
      value=$(printf "%s" "$generations" | cut -d' ' -f1)
      unit=$(printf "%s" "$generations" | cut -d' ' -f2 | sed 's/s$//')
      seconds=$(convert_to_seconds "$value" "$unit")
      cutoff_date=$(date -d "@$(expr "$(date +%s)" - $seconds)" +%Y-%m-%d)
      num_generations=$(nix-env --list-generations |
        awk -v cutoff="$cutoff_date" '$1 > cutoff {count++} END {print count}')
      ;;
    *[!0-9]*)
      # Timestamp
      num_generations=$(nix-env --list-generations |
        awk -v cutoff="$generations" '$1 > cutoff {count++} END {print count}')
      ;;
    *)
      # Pure number
      num_generations="$generations"
      ;;
    esac
    printf "%s" "$num_generations"
    ;;

  hm)
    case "$generations" in
    *[!0-9]*)
      if printf "%s" "$generations" | grep -q "[hdwmy]$"; then
        value=$(printf "%s" "$generations" | sed 's/[hdwmy]$//')
        unit=$(printf "%s" "$generations" | sed 's/.*\(.\)$/\1/')
        seconds=$(convert_to_seconds "$value" "$unit")
        target_timestamp=$(date -d "@$(expr "$(date +%s)" - $seconds)" +%Y-%m-%d)
      elif printf "%s" "$generations" | grep -q " "; then
        value=$(printf "%s" "$generations" | cut -d' ' -f1)
        unit=$(printf "%s" "$generations" | cut -d' ' -f2 | sed 's/s$//')
        seconds=$(convert_to_seconds "$value" "$unit")
        target_timestamp=$(date -d "@$(expr "$(date +%s)" - $seconds)" +%Y-%m-%d)
      else
        target_timestamp="$generations"
      fi
      ;;
    *)
      # Get the timestamp of the Nth oldest generation
      target_timestamp=$(home-manager generations |
        sort -k2,2 |
        head -n "$generations" |
        tail -n 1 |
        awk '{print $2}')
      ;;
    esac
    printf "%s" "$target_timestamp"
    ;;
  esac
}

gc_nix() {
  #{ Skip if 'nix' is not specified or installed
  [ -n "${nix}" ] ||
    validate_tool nix ||
    return 0

  #{ Delete old Nix profiles and generations
  validate_tool "nix-collect-garbage" && {
    expiry_date=$(set_expiry_date "${generations}")

    if [ "${expiry_date}" ]; then
      opt="--delete-older-than ${expiry_date}"
    else
      opt="--delete-old"
    fi

    nix-collect-garbage \
      --delete-older-than "$(set_expiry_date)" \
      --verbose "${verbosity:-0}"
  }

  nix-store --optimise
}

gc_home_manager() {
  #{ Skip if 'home-manager' is not specified or installed
  [ -n "${home_manager}" ] || return 0

  #{ Set generation expiry date to the current minute, if not specified
  [ -n "${generations}" ] || {
    # date --iso-8601=minutes
    # 2025-01-19 22:56:33
    date "+%Y-%m-%d %H:%M:%S"
    return 0
  }
  expiry_date=$(set_expiry_date "${generations}")
  home-manager expire-generations "${expiry_date}"

  #{ Remove old home-manager generations

}

#{ Clean up Home Manager generations
# weHave home-manager && home-manager expire-generations "$generations" --delete-old"

gc_rust() {
  #{ Skip if Rust is not specified of installed
  [ "${rust}" ] || weHave cargo || return 0

}

main "$@"
# main "$@" --debug
