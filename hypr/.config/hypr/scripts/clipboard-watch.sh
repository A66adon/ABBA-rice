#!/usr/bin/env bash
set -Eeuo pipefail

wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

wait
