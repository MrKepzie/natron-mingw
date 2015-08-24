Natron on Windows
==================

Scripts used to build and distribute [Natron](http://www.natron.fr) from Windows to Windows.

Build server installation
=========================

Requires any Windows machine (XP+).
These scripts make use of [MSYS2](https://sourceforge.net/projects/msys2/) to operate.  

Clone this repository 

    git clone https://github.com/MrKepzie/natron-mingw
	cd natron-mingw
	git submodule update -i --recursive

Create the local.sh file in the root of natron-mingw to specify various infos, e.g:

    #!/bin/sh

    REPO_DEST=mrkepzie@vps163799.ovh.net:../www/downloads.natron.fr
    REPO_URL=http://downloads.natron.fr
    

If this is the first time installing it, make sure to install all base packages by running:
	BIT=64
	sh include/scripts/setup-msys.sh $BIT
	sh include/scripts/build-sdk.sh $BIT
	
The environment is now ready to build Natron and plug-ins, just run:

	sh 
