#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Insert Date
# @raycast.mode silent

date '+%Y-%m-%d' | tr -d '\n' | pbcopy
osascript -e 'tell application "System Events" to keystroke "v" using command down'