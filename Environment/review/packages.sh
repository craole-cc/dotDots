#! /bin/sh

#==================================================
#
# WINGET
# CLI/bin/environment/app/fm6000.sh
#
#==================================================

# _________________________________ DOCUMENTATION<|

# --> https://docs.microsoft.com/en-us/windows/package-manager/winget/

# _________________________________________ LOCAL<|

# APP=winget

# ________________________________________ EXPORT<|

# ______________________________________ FUNCTION<|

# if weHave $APP; then
alias pacList="winget list | less"
# pacCount="$(winget list | wc -l)"
pacCount=137
# alias upTime="wmic os get LastBootUpTime"
export pacCount

# ----------------------------
# ---- Package Management ----
# ----------------------------

# >>= Refresh Mirrors =<< #
alias um="mirror"

# >>= Search Repositiries =<< #


# >>= Add and Remove =<< #
alias pa="paru -S"                                      # Add
alias fa="flatpak install"                              # Add

alias fr="flatpak uninstall"                            # Remove

alias fcl="flatpak uninstall --unused; flatpak repair"  # Remove Orphans




alias cin='cargoInstall'

# >>= Update =<< #
alias UP="pacUpdate"                                          # All

alias pL="type "                                                                          # Active location

alias has="curl -sL https://git.io/_has | bash -s"

alias pV="HAS_ALLOW_UNSAFE=y has"                                                         #Installed Version

alias fR="flatpak remotes"
alias fRD="flatpak remote-delete"