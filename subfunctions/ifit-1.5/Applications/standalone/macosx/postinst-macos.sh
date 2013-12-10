#!/bin/sh -e

# script: postinst-macos.sh

if [ ! -f "`which ifit`"  ]; then
echo creating shortcut /usr/bin/ifit
echo "open -a ifit" > /usr/bin/ifit
chmod a+x /usr/bin/ifit
fi

if [ ! -f "`which matlab`"  ]; then
echo creating shortcut /usr/bin/matlab
echo "open -a ifit" > /usr/bin/matlab
chmod a+x /usr/bin/matlab
fi

