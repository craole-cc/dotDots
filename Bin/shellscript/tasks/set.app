#!/bin/sh

key=$1
app=$2
ver=$3

key="$(printf "%s" "$key" | tr '[:lower:]' '[:upper:]')"

printf "%s=%s" "$key" "$app"
printf "%s_VERSION=%s" "$key" "$ver"
