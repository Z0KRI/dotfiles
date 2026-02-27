#!/bin/bash

# The active window closes.
hyprctl dispatch killactive

sleep 0.1

# The information is obtained from the current workspace.
WS_DATA=$(hyprctl activeworkspace -j)
WINDOW_COUNT=$(echo "$WS_DATA" | jq '.windows')

if [ "$WINDOW_COUNT" -eq 0 ]; then
    # We return to the previous workspace on this monitor.v
    hyprctl dispatch workspace previous
fi