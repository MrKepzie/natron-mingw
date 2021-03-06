**This repository has reached is end of life. It has been merged to [MrKepzie/Natron](https://github.com/MrKepzie/Natron/tree/workshop)**

Natron on Windows
==================

Scripts used to build and distribute [Natron](http://www.natron.fr) from Windows to Windows using MingW-w64 (via MSYS2).

Build server installation
=========================

Requires any Windows machine (XP+).
These scripts make use of [MSYS2](https://sourceforge.net/projects/msys2/) to operate.  

Create the local.sh file in the root of natron-mingw to specify various infos, e.g:

    #!/bin/sh

    REPO_DEST=user@host:/path
    REPO_URL=http://some.url
    

If this is the first time installing it, make sure to install all base packages by running:
	
	#Use BIT=32 or BIT=64
	BIT=64
	sh include/scripts/setup-msys.sh $BIT
	sh include/scripts/build-sdk.sh $BIT
	
The environment is now ready to build Natron and plug-ins, just run:
	
	#Use BIT=32 or BIT=64
	BIT=64
	sh snapshots.sh 64

	