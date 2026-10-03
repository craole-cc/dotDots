#!/bin/sh

name=$1
unused_value=1

echo $name
[ $name == "x" ] && echo "match"
files=$(ls)
cd /tmp
if [ -n "$name" -a -n "$files" ]; then
  echo "$name"
fi
