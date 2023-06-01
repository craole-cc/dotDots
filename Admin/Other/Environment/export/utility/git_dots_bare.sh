#! /bin/sh
# shellcheck disable=SC2154

#==================================================
#
# GIT
# ~/.config/git/gitalias
#
#==================================================

# _________________________________________ LOCAL<|

#> Install <#
if ! weHave git; then
  if weHave paru; then
    paru -S git
  elif weHave pacman; then
    sudo pacman -S git
  elif weHave choco; then
    cup git -y
  elif weHave winget; then
    winget install git
  elif weHave apt-get; then
    sudo apt-get install git
  elif weHave yum; then
    sudo yum install git
  fi
fi

#> Verify Instalation <#
weHave git || return

# __________________________________________ EXEC<|
# echo "$APP"
# ________________________________________ CONFIG<|

# --> Completion

# case "$sys_INFO" in
# *Git*) ;;
# *baSH*)
#   eval "$(gh completion -s bash)"
#   config
#   ;;
# *zSH*)
#   eval "$(gh completion -s zsh)"
#   config
#   ;;
# *) ;;
# esac
# ________________________________________ EXPORT<|

# config
# get() { git --git-dir="$gitBARE" --work-tree="$DOTS"; }
alias get='git --git-dir="$gitBARE" --work-tree="$DOTS"'

# --> Update Config
GetInit() {
  # --> Allow Update
  unset GIT_CONFIG

  gitBARE="${HOME}/.dots"
  gitWORK="${DOTS}"
  gitCONFIG="${gitBARE}/config"
  gitIGNORE="${GDOTDIR}/gitignore"
  gitNAME="${Name}"
  gitEMAIL="${Email}"

  if [ ! -d "${gitBARE}" ]; then
    mkdir --parents "${gitBARE}"
    git init --bare "${gitBARE}"
    get remote add remote git@gitlab.com:craole/dotfiles.git
  fi

  get config --local user.name "${gitNAME}"
  get config --local user.email "${gitEMAIL}"
  get config --local core.excludesfile "${gitIGNORE}"
  get config --local core.editor "${VISUAL}" --wait
  get config --local init.defaultBranch main
  get config --local status.showUntrackedFiles no
  get config --local --unset core.autocrlf
  get config --local core.autocrlf false
  get config --local core.safecrlf true
  # get config --local push.autoSetupRemote
  # git config --local fetch.prune true
  # git config --local alias.empty "git commit --allow-empty"

  export GIT_CONFIG="${gitCONFIG}"
}

# list
alias Gls='get config --list --show-origin'

# add
alias Ga='get add'
alias Gal='get add --all'
alias Gap='get add --patch'

# branch
alias Gb='get branch'
alias GbD='get branch -D'
alias Gba='get branch -a'
alias Gbd='get branch -d'
alias Gbm='get branch -m'
alias Gbt='get branch --track'
alias Gdel='get branch -D'

# for-each-ref
alias Gbc='get for-each-ref --format="%(authorname) %09 %(if)%(HEAD)%(then)*%(else)%(refname:short)%(end) %09 %(creatordate)" refs/remotes/ --sort=authorname DESC' # FROM https://stackoverflow.com/a/58623139/10362396

# commit
alias Gc='get commit -v'
alias Gca='get commit -v -a'
alias Gcaa='get commit -a --amend -C HEAD' # Add uncommitted and unstaged changes to the last commit
alias Gcam='get commit -v -am'
alias Gcamd='get commit --amend'
alias Gcm='get commit -v -m'
alias Gci='get commit --interactive'
alias Gcsam='get commit -S -am'

# checkout
alias Gcb='get checkout -b'
alias Gco='get checkout'
alias Gcob='get checkout -b'
alias Gcobu='get checkout -b ${USER}/'
alias Gcom='get checkout master'
alias Gcpd='get checkout master; get pull; get branch -D'
alias Gct='get checkout --track'

# clone
alias Gcl='get clone'

# clean
alias Gclean='get clean -fd'

# cherry-pick
alias Gcp='get cherry-pick'
alias Gcpx='get cherry-pick -x'

# diff
alias Gd='get diff'
alias Gds='get diff --staged'
alias Gdt='get difftool'

# archive
alias Gexport='get archive --format zip --output'

# fetch
alias Gf='get fetch --all --prune'
alias Gft='get fetch --all --prune --tags'
alias Gftv='get fetch --all --prune --tags --verbose'
alias Gfv='get fetch --all --prune --verbose'
alias Gmu='get fetch origin -v; get fetch upstream -v; get merge upstream/master'
alias Gup='get fetch && get rebase'

# log
alias Gg='get log --graph --pretty=format:'\''%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset'\'' --abbrev-commit --date=relative'
alias Ggf='get log --graph --date=short --pretty=format:'\''%C(auto)%h %Cgreen%an%Creset %Cblue%cd%Creset %C(auto)%d %s'\'''
alias Ggs='gg --stat'
alias Gll='get log --graph --pretty=oneline --abbrev-commit'
alias Gnew='get log HEAD@{1}..HEAD@{0}' # Show commits since last pull, see http://blogs.atlassian.com/2014/10/advanced-git-aliases/
alias Gwc='get whatchanged'

# ls-files
alias Gu='get ls-files . --exclude-standard --others' # Show untracked files
alias Glsut='gu'
alias Glsum='get diff --name-only --diff-filter=U' # Show unmerged (conflicted) files

# gui
alias Ggui='get gui'

# home
alias Ghm='cd "$gitWORK"' # Git home
# appendage to ghm
# if ! _command_exists gh; then
# 	alias Gh='ghm'
# fi

# merge
alias Gm='get merge'

# mv
alias Gmv='get mv'

# patch
alias Gpatch='get format-patch -1'

# push
alias Gp='get push'
alias Gpd='get push --delete'
alias Gpf='get push --force'
alias Gpo='get push origin HEAD'
alias Gpom='get push origin master'
alias Gpu='get push --set-upstream'
alias Gpunch='get push --force-with-lease'
alias Gpuo='get push --set-upstream origin'
alias Gpuoc='get push --set-upstream origin $(get symbolic-ref --short HEAD)'

# pull
alias Gl='get pull'
alias Glum='get pull upstream master'
alias Gpl='get pull'
alias Gpp='get pull && get push'
alias Gpr='get pull --rebase'

# remote
alias Gr='get remote'
alias Gra='get remote add'
alias Grv='get remote -v'

# rm
alias Grm='get rm'
alias Grmc='get rm -rf --cached .'

# rebase
alias Grb='get rebase'
alias Grbc='get rebase --continue'
alias Grbm='get rebase master'
alias Grbmi='get rebase master -i'
alias Gprbom='get fetch origin master && get rebase origin/master && get update-ref refs/heads/master origin/master' # Rebase with latest remote master

# reset
alias Gus='get reset HEAD'
alias Gpristine='get reset --hard && get clean -dfx'

# status
alias Gs='get status'
alias Gss='get status -s'

# shortlog
alias Gcount='get shortlog -sn'
alias Gsl='get shortlog -sn'

# show
alias Gsh='get show'

# svn
alias Gsd='get svn dcommit'
alias Gsr='get svn rebase' # Git SVN

# stash
alias Gst='get stash'
alias Gstb='get stash branch'
alias Gstd='get stash drop'
alias Gstl='get stash list'
alias Gstp='get stash pop'  # kept due to long-standing usage
alias Gstpo='get stash pop' # recommended for it's symmetry with gstpu (push)

## 'stash push' introduced in git v2.13.2
alias Gstpu='get stash push'
alias Gstpum='get stash push -m'

## 'stash save' deprecated since git v2.16.0, alias is now push
alias Gsts='get stash push'
alias Gstsm='get stash push -m'

# submodules
alias Gsu='get submodule update --init --recursive'

# switch
# these aliases requires git v2.23+
alias Gsw='get switch'
alias Gswc='get switch --create'
alias Gswm='get switch master'
alias Gswt='get switch --track'

# tag
alias Gt='get tag'
alias Gta='get tag -a'
alias Gtd='get tag -d'
alias Gtl='get tag -l'

# shellcheck disable=SC2154
case "${sys_INFO}" in
*Mac*)
  alias gtls="get tag -l | gsort -V"
  ;;
*)
  alias gtls='get tag -l | sort -V'
  ;;
esac

# # functions
Gdv() {
  get diff --ignore-all-space "$@" | vim -R -
}

GUP() {
  case $1 in
  -r | --reset)
    Grmc
    shift
    ;;
  *) ;;
  esac
  GetInit
  Gss
  Gal
  Gcam "$@"
  Gp
}
