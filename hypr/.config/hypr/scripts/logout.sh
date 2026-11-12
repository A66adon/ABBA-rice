#!/usr/bin/env bash
# Exit the current Hyprland session using the 0.57+ dispatcher syntax.
exec hyprctl dispatch 'hl.dsp.exit()'
