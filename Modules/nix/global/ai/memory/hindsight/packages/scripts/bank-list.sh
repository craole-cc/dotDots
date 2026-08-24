#!/bin/sh
#shellcheck enable=all
set -eu

exec docker exec hindsight hindsight-api bank list
