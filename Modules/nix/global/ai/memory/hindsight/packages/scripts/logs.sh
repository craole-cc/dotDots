#!/bin/sh
#shellcheck enable=all
set -eu

exec docker logs -f hindsight
