#!/bin/sh
#shellcheck enable=all
printf "%s" "$SEP1"
if [ -z "$(pgrep xautolock)" ]; then
	printf ""
else
	printf ""
fi
printf "%s" " "
