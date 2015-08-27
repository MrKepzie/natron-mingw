#!/bin/sh
#
# Build packages and installer for Linux
#

source $(pwd)/common.sh || exit 1
source $(pwd)/commits-hash.sh || exit 1

PID=$$
if [ -f $TMP_DIR/natron-build-installer.pid ]; then
  OLDPID=$(cat $TMP_DIR/natron-build-installer.pid)
  PIDS=$(ps aux|awk '{print $2}')
  for i in $PIDS;do
    if [ "$i" == "$OLDPID" ]; then
      echo "already running ..."
      exit 1
    fi
  done
fi
echo $PID > $TMP_DIR/natron-build-installer.pid || exit 1

if [ "$1" == "32" ]; then
	BIT=32
	INSTALL_PATH=$INSTALL32_PATH
else
	BIT=64
	INSTALL_PATH=$INSTALL64_PATH
fi

if [ "$2" == "workshop" ]; then
  NATRON_VERSION=$NATRON_DEVEL_GIT
  REPO_BRANCH=snapshots
else
  NATRON_VERSION=$NATRON_VERSION_NUMBER
  REPO_BRANCH=releases
fi

DATE=$(date +%Y-%m-%d)
PKGOS=Windows-x86_${BIT}bit
REPO_OS=Windows/$REPO_BRANCH/${BIT}bit/packages



if [ -d $TMP_PATH ]; then
  rm -rf $TMP_PATH || exit 1
fi
mkdir -p $TMP_PATH || exit 1

# SETUP
INSTALLER=$TMP_PATH/Natron-installer
XML=$INC_PATH/xml
QS=$INC_PATH/qs

mkdir -p $INSTALLER/config $INSTALLER/packages || exit 1
cat $INC_PATH/config/config.xml | sed "s/_VERSION_/${NATRON_VERSION_NUMBER}/;s#_OS_BRANCH_BIT_#${REPO_OS}#g;s#_URL_#${REPO_URL}#g" > $INSTALLER/config/config.xml || exit 1
cp $INC_PATH/config/*.png $INSTALLER/config/ || exit 1

# OFX IO
IO_DLL="LIBFFI-6.DLL LIBICUDT55.DLL LIBIDN-11.DLL LIBP11-KIT-0.DLL LIBTASN1-6.DLL LIBGMP-10.DLL LIBGNUTLS-30.DLL LIBHOGWEED-4-1.DLL LIBNETTLE-6-1.DLL LIBICUUC55.DLL LIBLCMS2-2.DLL LIBJASPER-1.DLL AVCODEC-56.DLL LIBGSM.DLL LIBLZMA-5.DLL LIBMP3LAME-0.DLL LIBOPENJPEG-5.DLL LIBOPUS-0.DLL LIBSCHROEDINGER-1.0-0.DLL LIBSPEEX-1.DLL LIBTHEORADEC-1.DLL LIBTHEORAENC-1.DLL LIBVORBIS-0.DLL LIBVORBISENC-2.DLL LIBVPX-1.DLL LIBWAVPACK-1.DLL SWRESAMPLE-1.DLL LIBORC-0.4-0.DLL LIBOGG-0.DLL LIBMODPLUG-1.DLL LIBRTMP-1.DLL AVFORMAT-56.DLL AVUTIL-54.DLL LIBHALF-2_2.DLL LIBILMIMF-2_2.DLL LIBIEX-2_2.DLL LIBILMTHREAD-2_2.DLL LIBIMATH-2_2.DLL LIBILMIMF-2_2.DLL LIBOPENIMAGEIO.DLL LIBGIF-7.DLL LIBJPEG-8.DLL LIBRAW_R-10.DLL LIBTIFF-5.DLL LIBWEBP-5.DLL LIBBOOST_THREAD-MT.DLL LIBBOOST_SYSTEM-MT.DLL LIBBOOST_REGEX-MT.DLL LIBBOOST_FILESYSTEM-MT.DLL SWSCALE-3.DLL"
OFX_IO_VERSION=$TAG
OFX_IO_PATH=$INSTALLER/packages/$IOPLUG_PKG
mkdir -p $OFX_IO_PATH/data $OFX_IO_PATH/meta $OFX_IO_PATH/data/Plugins || exit 1
cat $XML/openfx-io.xml | sed "s/_VERSION_/${OFX_IO_VERSION}/;s/_DATE_/${DATE}/" > $OFX_IO_PATH/meta/package.xml || exit 1
cat $QS/openfx-io.qs > $OFX_IO_PATH/meta/installscript.qs || exit 1
cat $INSTALL_PATH/docs/openfx-io/VERSION > $OFX_IO_PATH/meta/ofx-io-license.txt || exit 1
echo "" >> $OFX_IO_PATH/meta/ofx-io-license.txt || exit 1
cat $INSTALL_PATH/docs/openfx-io/LICENSE >> $OFX_IO_PATH/meta/ofx-io-license.txt || exit 1
cp -a $INSTALL_PATH/Plugins/IO.ofx.bundle $OFX_IO_PATH/data/Plugins/ || exit 1
for depend in $IO_DLL; do
  cp $INSTALL_PATH/bin/$depend $OFX_IO_PATH/data/Plugins/IO.ofx.bundle/Contents/Win$BIT/ || exit 1
done
cp $INSTALL_PATH/lib/{LIBOPENCOLORIO.DLL,LIBSEEXPR.DLL} $OFX_IO_PATH/data/Plugins/IO.ofx.bundle/Contents/Win$BIT/ || exit 1
strip -s $OFX_IO_PATH/data/Plugins/*/*/*/*

# OFX MISC
OFX_MISC_VERSION=$TAG
OFX_MISC_PATH=$INSTALLER/packages/$MISCPLUG_PKG
mkdir -p $OFX_MISC_PATH/data $OFX_MISC_PATH/meta $OFX_MISC_PATH/data/Plugins || exit 1
cat $XML/openfx-misc.xml | sed "s/_VERSION_/${OFX_MISC_VERSION}/;s/_DATE_/${DATE}/" > $OFX_MISC_PATH/meta/package.xml || exit 1
cat $QS/openfx-misc.qs > $OFX_MISC_PATH/meta/installscript.qs || exit 1
cat $INSTALL_PATH/docs/openfx-misc/VERSION > $OFX_MISC_PATH/meta/ofx-misc-license.txt || exit 1
echo "" >> $OFX_MISC_PATH/meta/ofx-misc-license.txt || exit 1
cat $INSTALL_PATH/docs/openfx-misc/LICENSE >> $OFX_MISC_PATH/meta/ofx-misc-license.txt || exit 1
cp -a $INSTALL_PATH/Plugins/{CImg,Misc}.ofx.bundle $OFX_MISC_PATH/data/Plugins/ || exit 1
strip -s $OFX_MISC_PATH/data/Plugins/*/*/*/*

# NATRON
NATRON_PATH=$INSTALLER/packages/$NATRON_PKG
mkdir -p $NATRON_PATH/meta $NATRON_PATH/data/docs $NATRON_PATH/data/bin || exit 1
cat $XML/natron.xml | sed "s/_VERSION_/${TAG}/;s/_DATE_/${DATE}/" > $NATRON_PATH/meta/package.xml || exit 1
cat $QS/natron.qs > $NATRON_PATH/meta/installscript.qs || exit 1
cp -a $INSTALL_PATH/docs/natron/* $NATRON_PATH/data/docs/ || exit 1
cat $INSTALL_PATH/docs/natron/LICENSE.txt > $NATRON_PATH/meta/natron-license.txt || exit 1
cp $INSTALL_PATH/bin/Natron* $NATRON_PATH/data/bin/ || exit 1
strip -s $NATRON_PATH/data/bin/Natron*
wget --no-check-certificate $NATRON_API_DOC || exit 1
mv natron.pdf $NATRON_PATH/data/docs/Natron_Python_API_Reference.pdf || exit 1
rm $NATRON_PATH/data/docs/TuttleOFX-README.txt || exit 1
strip -s $NATRON_PATH/data/bin/*


# OCIO
OCIO_VERSION=$COLOR_PROFILES_VERSION
OCIO_PATH=$INSTALLER/packages/$PROFILES_PKG
mkdir -p $OCIO_PATH/meta $OCIO_PATH/data/share || exit 1
cat $XML/ocio.xml | sed "s/_VERSION_/${OCIO_VERSION}/;s/_DATE_/${DATE}/" > $OCIO_PATH/meta/package.xml || exit 1
cat $QS/ocio.qs > $OCIO_PATH/meta/installscript.qs || exit 1
cp -a $INSTALL_PATH/share/OpenColorIO-Configs $OCIO_PATH/data/share/ || exit 1

# CORE LIBS
CLIBS_VERSION=$CORELIBS_VERSION
CLIBS_PATH=$INSTALLER/packages/$CORELIBS_PKG
mkdir -p $CLIBS_PATH/meta $CLIBS_PATH/data/bin $CLIBS_PATH/data/lib $CLIBS_PATH/data/share/pixmaps || exit 1
cat $XML/corelibs.xml | sed "s/_VERSION_/${CLIBS_VERSION}/;s/_DATE_/${DATE}/" > $CLIBS_PATH/meta/package.xml || exit 1
cat $QS/corelibs.qs > $CLIBS_PATH/meta/installscript.qs || exit 1

cp -a $INSTALL_PATH/share/qt4/plugins/imageformats $CLIBS_PATH/data/bin/ || exit 1
rm -f $CLIBS_PATH/data/bin/imageformats/*d4.dll
NATRON_DLL="LIBICONV-2.DLL LIBINTL-8.DLL GLEW32.DLL LIBGLIB-2.0-0.DLL LIBWINPTHREAD-1.DLL LIBGCC_S_SEH-1.DLL LIBSTDC++-6.DLL LIBBOOST_SERIALIZATION-MT.DLL LIBCAIRO-2.DLL LIBFREETYPE-6.DLL LIBBZ2-1.DLL LIBHARFBUZZ-0.DLL LIBPIXMAN-1-0.DLL LIBPNG16-16.DLL ZLIB1.DLL LIBEXPAT-1.DLL LIBFONTCONFIG-1.DLL LIBPYSIDE-PYTHON2.7.DLL LIBPYTHON2.7.DLL QTCORE4.DLL QTGUI4.DLL QTNETWORK4.DLL QTOPENGL4.DLL LIBSHIBOKEN-PYTHON2.7.DLL"
for depend in $NATRON_DLL; do
  cp $INSTALL_PATH/bin/$depend $CLIBS_PATH/data/bin/ || exit 1
done



# TODO: At this point send unstripped binaries (and debug binaries?) to Socorro server for breakpad

strip -s $CLIBS_PATH/data/bin/*
strip -s $CLIBS_PATH/data/bin/*/*

CORE_DOC=$CLIBS_PATH
echo "" >> $CORE_DOC/meta/3rdparty-license.txt 

#Copy Python distrib
mkdir -p $CLIBS_PATH/data/Plugins || exit 1
if [ "$PYV" == "3" ]; then
  cp -a $INSTALL_PATH/lib/python3.4 $CLIBS_PATH/data/lib/ || exit 1
  mv $CLIBS_PATH/data/lib/python3.4/site-packages/PySide $CLIBS_PATH/data/Plugins/ || exit 1
  (cd $CLIBS_PATH/data/lib/python3.4/site-packages; ln -sf ../../../Plugins/PySide . )
  rm -rf $CLIBS_PATH/data/lib/python3.4/{test,config-3.4m} || exit 1
else
  cp -a $INSTALL_PATH/lib/python2.7 $CLIBS_PATH/data/lib/ || exit 1
  mv $CLIBS_PATH/data/lib/python2.7/site-packages/PySide $CLIBS_PATH/data/Plugins/ || exit 1
  rm -rf $CLIBS_PATH/data/lib/python2.7/{test,config} || exit 1
fi
(cd $CLIBS_PATH ; find . -type d -name __pycache__ -exec rm -rf {} \;)
strip -s $CLIBS_PATH/data/Plugins/PySide/* $CLIBS_PATH/data/lib/python*/* $CLIBS_PATH/data/lib/python*/*/*

# OFX ARENA
ARENA_DLL="LIBCROCO-0.6-3.DLL LIBGOMP-1.DLL LIBGMODULE-2.0-0.DLL LIBGDK_PIXBUF-2.0-0.DLL LIBGOBJECT-2.0-0.DLL LIBGIO-2.0-0.DLL LIBFFI-6.DLL LIBLCMS2-2.DLL LIBPANGO-1.0-0.DLL LIBPANGOCAIRO-1.0-0.DLL LIBPANGOWIN32-1.0-0.DLL LIBPANGOFT2-1.0-0.DLL LIBRSVG-2-2.DLL LIBXML2-2.DLL"
OFX_ARENA_VERSION=$TAG
OFX_ARENA_PATH=$INSTALLER/packages/$ARENAPLUG_PKG
mkdir -p $OFX_ARENA_PATH/meta $OFX_ARENA_PATH/data/Plugins || exit 1
cat $XML/openfx-arena.xml | sed "s/_VERSION_/${OFX_ARENA_VERSION}/;s/_DATE_/${DATE}/" > $OFX_ARENA_PATH/meta/package.xml || exit 1
cat $QS/openfx-arena.qs > $OFX_ARENA_PATH/meta/installscript.qs || exit 1
cat $INSTALL_PATH/docs/openfx-arena/VERSION > $OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
echo "" >> $OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
cat $INSTALL_PATH/docs/openfx-arena/LICENSE >> $OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
cp -av $INSTALL_PATH/Plugins/Arena.ofx.bundle $OFX_ARENA_PATH/data/Plugins/ || exit 1
for depend in $ARENA_DLL; do
  cp $INSTALL_PATH/bin/$depend  $OFX_ARENA_PATH/data/Plugins/Arena.ofx.bundle/Contents/Win$BIT/ || exit 1
done
cp $INSTALL_PATH/lib/LIBOPENCOLORIO.DLL $OFX_ARENA_PATH/data/Plugins/Arena.ofx.bundle/Contents/Win$BIT/ || exit 1
strip -s $OFX_ARENA_PATH/data/Plugins/*/*/*/*
echo "ImageMagick License:" >> $OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
cat $INSTALL_PATH/docs/imagemagick/LICENSE >> $OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
#echo "LCMS License:" >>$OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1
#cat $INSTALL_PATH/docs/lcms/COPYING >>$OFX_ARENA_PATH/meta/ofx-extra-license.txt || exit 1

# OFX CV
CV_DLL="LIBOPENCV_CORE2411.DLL LIBOPENCV_IMGPROC2411.DLL LIBOPENCV_PHOTO2411.DLL"
OFX_CV_VERSION=$TAG
OFX_CV_PATH=$INSTALLER/packages/$CVPLUG_PKG
mkdir -p $OFX_CV_PATH/{data,meta} $OFX_CV_PATH/data/Plugins $OFX_CV_PATH/data/docs/openfx-opencv || exit 1
cat $XML/openfx-opencv.xml | sed "s/_VERSION_/${OFX_CV_VERSION}/;s/_DATE_/${DATE}/" > $OFX_CV_PATH/meta/package.xml || exit 1
cat $QS/openfx-opencv.qs > $OFX_CV_PATH/meta/installscript.qs || exit 1
cp -a $INSTALL_PATH/docs/openfx-opencv $OFX_CV_PATH/data/docs/ || exit 1
cat $OFX_CV_PATH/data/docs/openfx-opencv/README > $OFX_CV_PATH/meta/ofx-cv-license.txt || exit 1
cp -a $INSTALL_PATH/Plugins/{inpaint,segment}.ofx.bundle $OFX_CV_PATH/data/Plugins/ || exit 1
for depend in $CV_DLL; do
  cp -v $INSTALL_PATH/bin/$depend  $OFX_CV_PATH/data/Plugins/inpaint.ofx.bundle/Contents/Win$BIT/ || exit 1
done
cp  $OFX_CV_PATH/data/Plugins/inpaint.ofx.bundle/Contents/Win$BIT/*.DLL  $OFX_CV_PATH/data/Plugins/segment.ofx.bundle/Contents/Win$BIT/ || exit 1 
strip -s $OFX_CV_PATH/data/Plugins/*/*/*/*


#manifests

IO_MANIFEST=$OFX_IO_PATH/data/Plugins/IO.ofx.bundle/Contents/Win$BIT/manifest
cat <<EOF > $IO_MANIFEST
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
<assemblyIdentity name="IO" version="1.0.0.0" type="win32" processorArchitecture="amd64"/>
EOF
for depend in $IO_DLL; do
  echo "<file name=\"${depend}\"></file>" >> $IO_MANIFEST || exit 1
done
echo "</assembly>" >> $IO_MANIFEST || exit 1
cd $OFX_IO_PATH/data/Plugins/IO.ofx.bundle/Contents/Win$BIT || exit 1
mt -manifest manifest -outputresource:"IO.ofx;2"


ARENA_MANIFEST=$OFX_ARENA_PATH/data/Plugins/Arena.ofx.bundle/Contents/Win$BIT/manifest
cat <<EOF > $ARENA_MANIFEST
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
<assemblyIdentity name="Arena" version="1.0.0.0" type="win32" processorArchitecture="amd64"/>
EOF
for depend in $ARENA_DLL; do
  echo "<file name=\"${depend}\"></file>" >> $ARENA_MANIFEST || exit 1
done
echo "</assembly>" >> $ARENA_MANIFEST || exit 1
cd $OFX_ARENA_PATH/data/Plugins/Arena.ofx.bundle/Contents/Win$BIT || exit 1
mt -manifest manifest -outputresource:"Arena.ofx;2"


CV_MANIFEST=$OFX_CV_PATH/data/Plugins/inpaint.ofx.bundle/Contents/Win$BIT/manifest
cat <<EOF > $CV_MANIFEST
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
<assemblyIdentity name="CV" version="1.0.0.0" type="win32" processorArchitecture="amd64"/>
EOF
for depend in $CV_DLL; do
  echo "<file name=\"${depend}\"></file>" >> $CV_MANIFEST || exit 1
done
echo "</assembly>" >> $CV_MANIFEST || exit 1
cp $CV_MANIFEST $OFX_CV_PATH/data/Plugins/segment.ofx.bundle/Contents/Win$BIT/ || exit 1
cd $OFX_CV_PATH/data/Plugins/inpaint.ofx.bundle/Contents/Win$BIT || exit 1
mt -manifest manifest -outputresource:"inpaint.ofx;2"
cd $OFX_CV_PATH/data/Plugins/segment.ofx.bundle/Contents/Win$BIT || exit 1
mt -manifest manifest -outputresource:"segment.ofx;2"


# Clean and perms
(cd $INSTALLER; find . -type d -name .git -exec rm -rf {} \;)

# Build repo and package
if [ "$NO_INSTALLER" != "1" ]; then
  if [ "$1" == "workshop" ]; then
    ONLINE_TAG=snapshot
  else
    ONLINE_TAG=release
  fi

  ONLINE_INSTALL=Natron-${PKGOS}-online-install-$ONLINE_TAG.exe
  BUNDLED_INSTALL=Natron-$NATRON_VERSION-${PKGOS}.exe

  REPO_DIR=$REPO_DIR_PREFIX$ONLINE_TAG
  rm -rf $REPO_DIR

  mkdir -p $REPO_DIR/packages || exit 1

  $INSTALL_PATH/bin/repogen -v --update-new-components -p $INSTALLER/packages -c $INSTALLER/config/config.xml $REPO_DIR/packages || exit 1

  mkdir -p $REPO_DIR/installers || exit 1

  if [ "$OFFLINE" != "0" ]; then
    $INSTALL_PATH/bin/binarycreator -v -f -p $INSTALLER/packages -c $INSTALLER/config/config.xml -i $PACKAGES $REPO_DIR/installers/$BUNDLED_INSTALL || exit 1 
  fi

  $INSTALL_PATH/bin/binarycreator -v -n -p $INSTALLER/packages -c $INSTALLER/config/config.xml $ONLINE_INSTALL || exit 1
fi


echo "All Done!!!"
