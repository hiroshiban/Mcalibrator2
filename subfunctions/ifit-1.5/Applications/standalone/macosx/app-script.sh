#!/bin/sh 
# Script to open a terminal which launches iFit

open -a terminal standalone/ifit &

osascript  <<EOF
tell app "Terminal"
  set custom title of front window to "iFit (c) ILL <ifit.mccode.org>"
  set normal text color of front window to "blue"
end tell
EOF
