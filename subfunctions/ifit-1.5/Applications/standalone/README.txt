HOWTO create standalone applications for iFit:

Requires to have Matlab compiler installed (mcc).
To build the Debian packages, a Debian minimal system must be created 
one level above the 'trunk' with
% sudo debootstrap --arch $ARCH precise build-chroot-$ARCH

Linux (Debian/Ubuntu, works on amd64 and i386):
-----------------------------------------------
  1- navigate into svn 'trunk'
  2- launch: % ./mkdist <major.minor>
will create a src.zip source, a <arch>.zip linux binary and a <arch>.deb

Mac OSX (prefer i386 which also work in 64 bits):
----------------------
  1- copy the ifit-src.zip file for the distribution to MacOSX
  2- launch matlab and navigate to ifit-src directory
  3- type: addpath(genpath(pwd))
  4- launch: >> ifitdeploy
will create a 'ifit-maci' binary distribution.

To create a MacOSX App:
----------------------
If such a package already exists, open it with 'show package content', and just 
copy the new binary files inside 'Contents/Resources/standalone'

To get Platypus:
  <http://sveinbjorn.org/platypus>
  <http://download.cnet.com/Platypus/3000-2247_4-40832.html>
  
  1- launch Platypus, set app title to 'iFit'
  2- use the ifit-src/Applications/standalone/macosx/app-script.sh script
  
#!/bin/sh 
# Script to open a terminal which launches iFit

open -a terminal standalone/ifit &

osascript  <<EOF
tell app "Terminal"
  set custom title of front window to "iFit (c) ILL <ifit.mccode.org>"
  set normal text color of front window to "blue"
end tell
EOF

  3- set the icon to ifit-src/Docs/images/iFit-logo.png (drag-n-drop from iFit src directory)
  4- set output to None, version number, allow drag-n-drop, uncheck 'remain running'
  5- drag-n-drop the 'ifit-maci' binary distribution directory renamed as 'standalone'
  6- click create, and select XML plist as non-binary (easier to edit)
an 'iFit.app' is created.

To create a MacOSX installer:
-----------------------------
  1- open /osx/Developer/Applications/Utilities/PackageMaker
  2- in left panel iFit Tab:Configuration:Description
    Title: iFit
    Check 'System Volume' only
    iFit: Requirements: none (triggers JavaScript error)
    iFit: Actions: Show File in Finder: /Applications after installation
    iFit: Desciption
    
iFit generic data analysis and fitting to models
Simple methods to be used for complex data analysis

The iFit program provides a set of methods to load, analyze, plot, fit and optimize models, and export results. iFit is based on Matlab, but stand-alone version does not require a Matlab license to run. Any text file can be imported straight away, and a set of binary files are supported. Any data dimensionality can be handled, including event based data sets.

The spirit of the software is to include simple object definitions for Data sets and Models, with a set of methods that provide all the means to perform the usual data analysis procedures.
 - iData objects to hold data sets ; Import with:          iData('filename')
 - iFunc objects to hold models ;    Create new ones with: iFunc('expression')
 - fit model to data with: fits(data, model)
 - documentation is available
 
Main functionalities are: [ iData Load Plot Math Fit Save Optimization iFunc Models ]
 
To use this software, you need to install the Matlab Compiler Runtime from the DMG available in the ifit.mccode.org website / Download binary section.

To start iFit, start it from the Applications folder.

Refer to <ifit.mccode.org> for on-line documentation.
Matlab is a registered trademark of The Mathworks Inc.

  3- Copy iFit.app inside Contents left panel.
  4- in left panel Contents:iFit Tab:Configuration
    Name: iFit
    Initial State: Selected_Enabled
    Destination: /Applications (do not allow alternate volume)
    Tooltip: The iFit standalone Matlab(R) application

  5- in left panel Contents:iFit/Applications Tab:Configuration
    Destination: /Applications (no custom location)
    Package ID: ill.eu.ifit.iFit.pkg
    Version: 1.5
    Require admin auth

  6- in left panel Contents:iFit/Applications Tab:Contents
    Click Include root in package
    Click Apply Recommendations

  7- in left panel Contents:iFit/Applications Tab:Components
    Do NOT allow relocation

  8- in left panel Contents:iFit/Applications Tab:Scripts
    Postinstall: Relative to project: postinst-macos.sh
      use ifit-src/Applications/standalone/macosx/postinst-macos.sh script

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

  9- click Build and get the iFit.pkg installer
  
  
To create a Windows Installer:
------------------------------
  1- copy ifit-src to C:\ (required to properly mex files)
  2- launch ifit-src/ifitdeploy
  3- rename binary target as ifit-binary and copy it as Desktop/stabdalone/ifit-binary
  4- install wItem install from <http://www.witemsoft.com/>
  5- start wItem and open iFit.wip template
    from ifit-src/Applications/standalone/win32/iFit.wip
  6- select Menu Build
  
  
  
