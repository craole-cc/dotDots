#!/bin/sh

#> Install <#
if ! weHave firewalld; then
    if weHave paru; then
        paru -S firewalld
    elif weHave choco; then
        choco install firewalld
    elif weHave winget; then
        winget install firewalld
    else
        cargo install firewalld
    fi
fi

#> Verify Instalation <#
if ! weHave firewalld; then
    #     ver firewalld >>"$DOTS_loaded_apps"
    # else
    return
fi

alias fwup='sudo systemctl start firewalld'
alias fwdown='sudo systemctl stop firewalld'
alias fwr='sudo firewall-cmd --reload'
alias fwstat='sudo systemctl status firewalld'
alias fwchk='sudo firewall-cmd --state'
alias fwon='sudo systemctl enable firewalld'
alias fwoff='sudo systemctl enable firewalld'
