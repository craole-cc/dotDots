_rustup() {
  local i cur prev opts cmd
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  cmd=""
  opts=""

  for i in ${COMP_WORDS[@]}; do
    case "${cmd},${i}" in
    ",$1")
      cmd="rustup"
      ;;
    rustup,check)
      cmd="rustup__check"
      ;;
    rustup,completions)
      cmd="rustup__completions"
      ;;
    rustup,component)
      cmd="rustup__component"
      ;;
    rustup,default)
      cmd="rustup__default"
      ;;
    rustup,doc)
      cmd="rustup__doc"
      ;;
    rustup,dump-testament)
      cmd="rustup__dump__testament"
      ;;
    rustup,help)
      cmd="rustup__help"
      ;;
    rustup,install)
      cmd="rustup__install"
      ;;
    rustup,override)
      cmd="rustup__override"
      ;;
    rustup,run)
      cmd="rustup__run"
      ;;
    rustup,self)
      cmd="rustup__self"
      ;;
    rustup,set)
      cmd="rustup__set"
      ;;
    rustup,show)
      cmd="rustup__show"
      ;;
    rustup,target)
      cmd="rustup__target"
      ;;
    rustup,toolchain)
      cmd="rustup__toolchain"
      ;;
    rustup,uninstall)
      cmd="rustup__uninstall"
      ;;
    rustup,update)
      cmd="rustup__update"
      ;;
    rustup,which)
      cmd="rustup__which"
      ;;
    rustup__component,add)
      cmd="rustup__component__add"
      ;;
    rustup__component,help)
      cmd="rustup__component__help"
      ;;
    rustup__component,list)
      cmd="rustup__component__list"
      ;;
    rustup__component,remove)
      cmd="rustup__component__remove"
      ;;
    rustup__component__help,add)
      cmd="rustup__component__help__add"
      ;;
    rustup__component__help,help)
      cmd="rustup__component__help__help"
      ;;
    rustup__component__help,list)
      cmd="rustup__component__help__list"
      ;;
    rustup__component__help,remove)
      cmd="rustup__component__help__remove"
      ;;
    rustup__help,check)
      cmd="rustup__help__check"
      ;;
    rustup__help,completions)
      cmd="rustup__help__completions"
      ;;
    rustup__help,component)
      cmd="rustup__help__component"
      ;;
    rustup__help,default)
      cmd="rustup__help__default"
      ;;
    rustup__help,doc)
      cmd="rustup__help__doc"
      ;;
    rustup__help,dump-testament)
      cmd="rustup__help__dump__testament"
      ;;
    rustup__help,help)
      cmd="rustup__help__help"
      ;;
    rustup__help,install)
      cmd="rustup__help__install"
      ;;
    rustup__help,override)
      cmd="rustup__help__override"
      ;;
    rustup__help,run)
      cmd="rustup__help__run"
      ;;
    rustup__help,self)
      cmd="rustup__help__self"
      ;;
    rustup__help,set)
      cmd="rustup__help__set"
      ;;
    rustup__help,show)
      cmd="rustup__help__show"
      ;;
    rustup__help,target)
      cmd="rustup__help__target"
      ;;
    rustup__help,toolchain)
      cmd="rustup__help__toolchain"
      ;;
    rustup__help,uninstall)
      cmd="rustup__help__uninstall"
      ;;
    rustup__help,update)
      cmd="rustup__help__update"
      ;;
    rustup__help,which)
      cmd="rustup__help__which"
      ;;
    rustup__help__component,add)
      cmd="rustup__help__component__add"
      ;;
    rustup__help__component,list)
      cmd="rustup__help__component__list"
      ;;
    rustup__help__component,remove)
      cmd="rustup__help__component__remove"
      ;;
    rustup__help__override,list)
      cmd="rustup__help__override__list"
      ;;
    rustup__help__override,set)
      cmd="rustup__help__override__set"
      ;;
    rustup__help__override,unset)
      cmd="rustup__help__override__unset"
      ;;
    rustup__help__self,uninstall)
      cmd="rustup__help__self__uninstall"
      ;;
    rustup__help__self,update)
      cmd="rustup__help__self__update"
      ;;
    rustup__help__self,upgrade-data)
      cmd="rustup__help__self__upgrade__data"
      ;;
    rustup__help__set,auto-self-update)
      cmd="rustup__help__set__auto__self__update"
      ;;
    rustup__help__set,default-host)
      cmd="rustup__help__set__default__host"
      ;;
    rustup__help__set,profile)
      cmd="rustup__help__set__profile"
      ;;
    rustup__help__show,active-toolchain)
      cmd="rustup__help__show__active__toolchain"
      ;;
    rustup__help__show,home)
      cmd="rustup__help__show__home"
      ;;
    rustup__help__show,profile)
      cmd="rustup__help__show__profile"
      ;;
    rustup__help__target,add)
      cmd="rustup__help__target__add"
      ;;
    rustup__help__target,list)
      cmd="rustup__help__target__list"
      ;;
    rustup__help__target,remove)
      cmd="rustup__help__target__remove"
      ;;
    rustup__help__toolchain,install)
      cmd="rustup__help__toolchain__install"
      ;;
    rustup__help__toolchain,link)
      cmd="rustup__help__toolchain__link"
      ;;
    rustup__help__toolchain,list)
      cmd="rustup__help__toolchain__list"
      ;;
    rustup__help__toolchain,uninstall)
      cmd="rustup__help__toolchain__uninstall"
      ;;
    rustup__override,help)
      cmd="rustup__override__help"
      ;;
    rustup__override,list)
      cmd="rustup__override__list"
      ;;
    rustup__override,set)
      cmd="rustup__override__set"
      ;;
    rustup__override,unset)
      cmd="rustup__override__unset"
      ;;
    rustup__override__help,help)
      cmd="rustup__override__help__help"
      ;;
    rustup__override__help,list)
      cmd="rustup__override__help__list"
      ;;
    rustup__override__help,set)
      cmd="rustup__override__help__set"
      ;;
    rustup__override__help,unset)
      cmd="rustup__override__help__unset"
      ;;
    rustup__self,help)
      cmd="rustup__self__help"
      ;;
    rustup__self,uninstall)
      cmd="rustup__self__uninstall"
      ;;
    rustup__self,update)
      cmd="rustup__self__update"
      ;;
    rustup__self,upgrade-data)
      cmd="rustup__self__upgrade__data"
      ;;
    rustup__self__help,help)
      cmd="rustup__self__help__help"
      ;;
    rustup__self__help,uninstall)
      cmd="rustup__self__help__uninstall"
      ;;
    rustup__self__help,update)
      cmd="rustup__self__help__update"
      ;;
    rustup__self__help,upgrade-data)
      cmd="rustup__self__help__upgrade__data"
      ;;
    rustup__set,auto-self-update)
      cmd="rustup__set__auto__self__update"
      ;;
    rustup__set,default-host)
      cmd="rustup__set__default__host"
      ;;
    rustup__set,help)
      cmd="rustup__set__help"
      ;;
    rustup__set,profile)
      cmd="rustup__set__profile"
      ;;
    rustup__set__help,auto-self-update)
      cmd="rustup__set__help__auto__self__update"
      ;;
    rustup__set__help,default-host)
      cmd="rustup__set__help__default__host"
      ;;
    rustup__set__help,help)
      cmd="rustup__set__help__help"
      ;;
    rustup__set__help,profile)
      cmd="rustup__set__help__profile"
      ;;
    rustup__show,active-toolchain)
      cmd="rustup__show__active__toolchain"
      ;;
    rustup__show,help)
      cmd="rustup__show__help"
      ;;
    rustup__show,home)
      cmd="rustup__show__home"
      ;;
    rustup__show,profile)
      cmd="rustup__show__profile"
      ;;
    rustup__show__help,active-toolchain)
      cmd="rustup__show__help__active__toolchain"
      ;;
    rustup__show__help,help)
      cmd="rustup__show__help__help"
      ;;
    rustup__show__help,home)
      cmd="rustup__show__help__home"
      ;;
    rustup__show__help,profile)
      cmd="rustup__show__help__profile"
      ;;
    rustup__target,add)
      cmd="rustup__target__add"
      ;;
    rustup__target,help)
      cmd="rustup__target__help"
      ;;
    rustup__target,list)
      cmd="rustup__target__list"
      ;;
    rustup__target,remove)
      cmd="rustup__target__remove"
      ;;
    rustup__target__help,add)
      cmd="rustup__target__help__add"
      ;;
    rustup__target__help,help)
      cmd="rustup__target__help__help"
      ;;
    rustup__target__help,list)
      cmd="rustup__target__help__list"
      ;;
    rustup__target__help,remove)
      cmd="rustup__target__help__remove"
      ;;
    rustup__toolchain,help)
      cmd="rustup__toolchain__help"
      ;;
    rustup__toolchain,install)
      cmd="rustup__toolchain__install"
      ;;
    rustup__toolchain,link)
      cmd="rustup__toolchain__link"
      ;;
    rustup__toolchain,list)
      cmd="rustup__toolchain__list"
      ;;
    rustup__toolchain,uninstall)
      cmd="rustup__toolchain__uninstall"
      ;;
    rustup__toolchain__help,help)
      cmd="rustup__toolchain__help__help"
      ;;
    rustup__toolchain__help,install)
      cmd="rustup__toolchain__help__install"
      ;;
    rustup__toolchain__help,link)
      cmd="rustup__toolchain__help__link"
      ;;
    rustup__toolchain__help,list)
      cmd="rustup__toolchain__help__list"
      ;;
    rustup__toolchain__help,uninstall)
      cmd="rustup__toolchain__help__uninstall"
      ;;
    *) ;;
    esac
  done

  case "${cmd}" in
  rustup)
    opts="-v -q -h -V --verbose --quiet --help --version [+toolchain] dump-testament show install uninstall update check default toolchain target component override run which doc self set completions help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__check)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__completions)
    opts="-h --help bash elvish fish powershell zsh rustup cargo"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component)
    opts="-h --help list add remove help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__add)
    opts="-h --toolchain --target --help <component>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    --target)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__help)
    opts="list add remove help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__help__add)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__help__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__help__remove)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__list)
    opts="-h --toolchain --installed --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__component__remove)
    opts="-h --toolchain --target --help <component>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    --target)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__default)
    opts="-h --help [toolchain]"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__doc)
    opts="-h --path --toolchain --alloc --book --cargo --core --edition-guide --nomicon --proc_macro --reference --rust-by-example --rustc --rustdoc --std --test --unstable-book --embedded-book --help [topic]"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__dump__testament)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help)
    opts="dump-testament show install uninstall update check default toolchain target component override run which doc self set completions help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__check)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__completions)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__component)
    opts="list add remove"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__component__add)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__component__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__component__remove)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__default)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__doc)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__dump__testament)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__install)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__override)
    opts="list set unset"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__override__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__override__set)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__override__unset)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__run)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__self)
    opts="update uninstall upgrade-data"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__self__uninstall)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__self__update)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__self__upgrade__data)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__set)
    opts="default-host profile auto-self-update"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__set__auto__self__update)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__set__default__host)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__set__profile)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__show)
    opts="active-toolchain home profile"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__show__active__toolchain)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__show__home)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__show__profile)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__target)
    opts="list add remove"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__target__add)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__target__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__target__remove)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__toolchain)
    opts="list install uninstall link"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__toolchain__install)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__toolchain__link)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__toolchain__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__toolchain__uninstall)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__uninstall)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__update)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__help__which)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__install)
    opts="-h --profile --no-self-update --force --force-non-host --help <toolchain>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --profile)
      COMPREPLY=($(compgen -W "minimal default complete" -- "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override)
    opts="-h --help list set unset help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__help)
    opts="list set unset help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__help__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__help__set)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__help__unset)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__list)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__set)
    opts="-h --path --help <toolchain>"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --path)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__override__unset)
    opts="-h --path --nonexistent --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --path)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__run)
    opts="-h --install --help <toolchain> <command>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self)
    opts="-h --help update uninstall upgrade-data help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__help)
    opts="update uninstall upgrade-data help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__help__uninstall)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__help__update)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__help__upgrade__data)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__uninstall)
    opts="-y -h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__update)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__self__upgrade__data)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set)
    opts="-h --help default-host profile auto-self-update help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__auto__self__update)
    opts="-h --help enable disable check-only"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__default__host)
    opts="-h --help <host_triple>"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__help)
    opts="default-host profile auto-self-update help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__help__auto__self__update)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__help__default__host)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__help__profile)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__set__profile)
    opts="-h --help minimal default complete"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show)
    opts="-v -h --verbose --help active-toolchain home profile help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__active__toolchain)
    opts="-v -h --verbose --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__help)
    opts="active-toolchain home profile help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__help__active__toolchain)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__help__home)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__help__profile)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__home)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__show__profile)
    opts="-h --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target)
    opts="-h --help list add remove help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__add)
    opts="-h --toolchain --help <target>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__help)
    opts="list add remove help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__help__add)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__help__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__help__remove)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__list)
    opts="-h --toolchain --installed --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__target__remove)
    opts="-h --toolchain --help <target>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain)
    opts="-h --help list install uninstall link help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help)
    opts="list install uninstall link help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help__help)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help__install)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help__link)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help__list)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__help__uninstall)
    opts=""
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 4 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__install)
    opts="-c -t -h --profile --component --target --no-self-update --force --allow-downgrade --force-non-host --help <toolchain>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --profile)
      COMPREPLY=($(compgen -W "minimal default complete" -- "${cur}"))
      return 0
      ;;
    --component)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    -c)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    --target)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    -t)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__link)
    opts="-h --help <toolchain> <path>"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__list)
    opts="-v -h --verbose --help"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__toolchain__uninstall)
    opts="-h --help <toolchain>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 3 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__uninstall)
    opts="-h --help <toolchain>..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__update)
    opts="-h --no-self-update --force --force-non-host --help [toolchain]..."
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  rustup__which)
    opts="-h --toolchain --help <command>"
    if [[ ${cur} == -* || ${COMP_CWORD} -eq 2 ]]; then
      COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      return 0
    fi
    case "${prev}" in
    --toolchain)
      COMPREPLY=($(compgen -f "${cur}"))
      return 0
      ;;
    *)
      COMPREPLY=()
      ;;
    esac
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
    ;;
  esac
}

command -v complete >/dev/null &&
  if [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 4 || "${BASH_VERSINFO[0]}" -gt 4 ]]; then
    complete -F _rustup -o nosort -o bashdefault -o default rustup
  else
    complete -F _rustup -o bashdefault -o default rustup
  fi
