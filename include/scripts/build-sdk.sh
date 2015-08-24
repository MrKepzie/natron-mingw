#!/bin/sh

#options:
#TAR_SDK=1 : Make an archive of the SDK when building is done and store it in $SRC_PATH
#UPLOAD_SDK=1 : Upload the SDK tar archive to $REPO_DEST if TAR_SDK=1

source $(pwd)/common.sh || exit 1


if [ "$1" == "32" ]; then
    BIT=32
    INSTALL_PATH=$INSTALL32_PATH
	PKG_PREFIX=$PKG_PREFIX32
elif [ "$1" == "64" ]; then
    BIT=64
    INSTALL_PATH=$INSTALL64_PATH
	PKG_PREFIX=$PKG_PREFIX64
else
    echo "Usage build-sdk.sh <BIT>"
    exit 1
fi


BINARIES_URL=$REPO_DEST/Third_Party_Binaries
SDK=Windows-$OS-SDK

if [ -z "$MKJOBS" ]; then
    #Default to 4 threads
    MKJOBS=$DEFAULT_MKJOBS
fi



echo
echo "Building $SDK using with $MKJOBS threads using gcc ${GCC_MAJOR}.${GCC_MINOR} ..."
echo
sleep 2

if [ ! -z "$REBUILD" ]; then
  if [ -d $INSTALL_PATH ]; then
    rm -rf $INSTALL_PATH || exit 1
  fi
fi
if [ -d $TMP_PATH ]; then
  rm -rf $TMP_PATH || exit 1
fi
mkdir -p $TMP_PATH || exit 1
if [ ! -d $SRC_PATH ]; then
  mkdir -p $SRC_PATH || exit 1
fi

#Make sure GCC is installed
if [ ! -f ${INSTALL_PATH}/bin/gcc ]; then
	echo "Make sure to run include/scripts/setup-msys.sh first"
	exit 1
fi

# Setup env
export QTDIR=$INSTALL_PATH
export BOOST_ROOT=$INSTALL_PATH
export OPENJPEG_HOME=$INSTALL_PATH
export THIRD_PARTY_TOOLS_HOME=$INSTALL_PATH
export PYTHON_HOME=$INSTALL_PATH
export PYTHON_PATH=$INSTALL_PATH/lib/python2.7
export PYTHON_INCLUDE=$INSTALL_PATH/include/python2.7


# Install magick
if [ "$REBUILD_MAGICK" == "1" ]; then
  rm -rf $INSTALL_PATH/include/ImageMagick-6/ $INSTALL_PATH/lib/libMagick* $INSTALL_PATH/share/ImageMagick-6/ $INSTALL_PATH/lib/pkgconfig/{Image,Magick}*
fi
if [ ! -f $INSTALL_PATH/lib/pkgconfig/Magick++.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$MAGICK_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$MAGICK_TAR -O $SRC_PATH/$MAGICK_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$MAGICK_TAR || exit 1
  cd ImageMagick-* || exit 1
  env CFLAGS="-DMAGICKCORE_EXCLUDE_DEPRECATED=1" CXXFLAGS="-I${INSTALL_PATH}/include -DMAGICKCORE_EXCLUDE_DEPRECATED=1"  ./configure --prefix=$INSTALL_PATH --with-magick-plus-plus=yes --with-quantum-depth=32 --without-dps --without-djvu --without-fftw --without-fpx --without-gslib --without-gvc --without-jbig --without-jpeg --without-lcms --with-lcms2 --without-openjp2 --without-lqr --without-lzma --without-openexr --with-pango --with-png --with-rsvg --without-tiff --without-webp --with-xml --without-zlib --without-bzlib --enable-static --disable-shared --enable-hdri --with-freetype --with-fontconfig --without-x --without-modules --without-threads || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/imagemagick || exit 1
  cp LIC* COP* Copy* Lic* README AUTH* CONT* $INSTALL_PATH/docs/imagemagick/
fi


# Install ocio
if [ ! -f $INSTALL_PATH/lib/libOpenColorIO.a ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$OCIO_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$OCIO_TAR -O $SRC_PATH/$OCIO_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$OCIO_TAR || exit 1
  cd OpenColorIO-* || exit 1
  OCIO_PATCHES=$CWD/include/patches/OpenColorIO
  patch -p1 -i ${OCIO_PATCHES}/mingw-w64.patch || exit 1
  patch -p1 -i ${OCIO_PATCHES}/fix-redefinitions.patch || exit 1
  patch -p1 -i ${OCIO_PATCHES}/detect-mingw-python.patch || exit 1

  mkdir build || exit 1
  cd build || exit 1
  cmake -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DOCIO_BUILD_SHARED=ON -DOCIO_BUILD_STATIC=ON  -DOCIO_BUILD_PYGLUE=OFF -DOCIO_USE_BOOST_PTR=ON -DOCIO_BUILD_APPS=OFF .. || exit 1
  make || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/ocio || exit 1
  cp ../LICENSE ../README $INSTALL_PATH/docs/ocio/ || exit 1
fi

# Install oiio
if [ "$REBUILD_OIIO" == "1" ]; then
  rm -rf $INSTALL_PATH/lib/libOpenImage* $INSTALL_PATH/include/OpenImage*
fi
if [ ! -f $INSTALL_PATH/lib/libOpenImageIO.a ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$OIIO_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$OIIO_TAR -O $SRC_PATH/$OIIO_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$OIIO_TAR || exit 1
  cd oiio-Release-* || exit 1
  OIIO_PATCHES=$CWD/include/patches/OpenImageIO
  patch -p1 -i ${OIIO_PATCHES}/fix-mingw-w64.patch  || exit 1
  patch -p1 -i ${OIIO_PATCHES}/workaround-ansidecl-h-PTR-define-conflict.patch || exit 1
  patch -p1 -i ${OIIO_PATCHES}/0001-MinGW-w64-include-winbase-h-early-for-TCHAR-types.patch  || exit 1
  patch -p1 -i ${OIIO_PATCHES}/0002-Also-link-to-opencv_videoio-library.patch  || exit 1

  mkdir build || exit 1
  cd build || exit 1
  cmake -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DBUILDSTATIC=ON -DUSE_OPENSSL:BOOL=FALSE -DOPENEXR_HOME=$INSTALL_PATH -DILMBASE_HOME=$INSTALL_PATH -DTHIRD_PARTY_TOOLS_HOME=$INSTALL_PATH -DUSE_QT:BOOL=FALSE -DUSE_TBB:BOOL=FALSE -DUSE_PYTHON:BOOL=FALSE -DUSE_FIELD3D:BOOL=FALSE -DUSE_OPENJPEG:BOOL=TRUE  -DOIIO_BUILD_TESTS=0 -DOIIO_BUILD_TOOLS=0 -DLIBRAW_PATH=$INSTALL_PATH -DBOOST_ROOT=$INSTALL_PATH -DSTOP_ON_WARNING:BOOL=FALSE -DUSE_GIF:BOOL=TRUE -DUSE_FREETYPE:BOOL=TRUE -DFREETYPE_INCLUDE_PATH=$INSTALL_PATH/include -DUSE_FFMPEG:BOOL=FALSE .. || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/oiio || exit 1
  cp ../LICENSE ../README* ../CREDITS $INSTALL_PATH/docs/oiio || exit 1
fi

# Install opencv
if [ ! -f $INSTALL_PATH/lib/pkgconfig/opencv.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $CWD/src/$CV_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$CV_TAR -O $CWD/src/$CV_TAR || exit 1
  fi
  unzip $CWD/src/$CV_TAR || exit 1
  CV_PATCHES=$CWD/include/patches/OpenCV
  cd opencv* || exit 1
  patch -p0 -i "${CV_PATCHES}/mingw-w64-cmake.patch" || exit 1
  patch -Np1 -i "${CV_PATCHES}/free-tls-keys-on-dll-unload.patch" || exit 1
  patch -Np1 -i "${CV_PATCHES}/solve_deg3-underflow.patch" || exit 1
  mkdir build || exit 1
  cd build || exit 1
  CMAKE_INCLUDE_PATH="$INSTALL_PATH/include $(pwd)" CMAKE_LIBRARY_PATH=$INSTALL_PATH/lib CPPFLAGS="-I${INSTALL_PATH}/include" LDFLAGS="-L${INSTALL_PATH}/lib" cmake -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DWITH_GTK=OFF -DWITH_GSTREAMER=OFF -DWITH_FFMPEG=OFF -DWITH_OPENEXR=OFF -DWITH_OPENCL=OFF -DWITH_OPENGL=ON -DBUILD_WITH_DEBUG_INFO=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_EXAMPLES=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_SSE3=OFF ..  || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/opencv || exit 1
  cp ../LIC* ../COP* ../README ../AUTH* ../CONT* $INSTALL_PATH/docs/opencv/
fi

# Install ffmpeg
# Todo: do a full build of ffmpeg with all dependencies (LGPL only)
if [ "$REBUILD_FFMPEG" == "1" ]; then
  rm -rf $INSTALL_PATH/bin/ff* $INSTALL_PATH/lib/libav* $INSTALL_PATH/lib/libsw* $INSTALL_PATH/include/libav* $INSTALL_PATH/lib/pkgconfig/libav*
fi
if [ ! -f $INSTALL_PATH/lib/pkgconfig/libavcodec.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$FFMPEG_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$FFMPEG_TAR -O $SRC_PATH/$FFMPEG_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$FFMPEG_TAR || exit 1
  cd ffmpeg-2* || exit 1
  CFLAGS="$BF" CXXFLAGS="$BF" CPPFLAGS="-I${INSTALL_PATH}/include" LDFLAGS="-L${INSTALL_PATH}/lib" ./configure --prefix=$INSTALL_PATH --libdir=$INSTALL_PATH/lib --enable-shared --disable-static || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/ffmpeg || exit 1
  cp COPYING.LGPLv2.1 CREDITS $INSTALL_PATH/docs/ffmpeg/
fi

# Install shiboken
if [ ! -f $INSTALL_PATH/lib/pkgconfig/shiboken-py2.pc ]; then
  cd $MINGW_PACKAGES_PATH/${MINGW_PREFIX}shiboken-qt4 || exit 1
  makepkg-mingw -sLfC
  pacman --force -U ${PKG_PREFIX}shiboken-1.2.2-1-any.pkg.tar.xz
  pacman --force -U ${PKG_PREFIX}python2-shiboken-1.2.2-1-any.pkg.tar.xz
  pacman --force -U ${PKG_PREFIX}python3-shiboken-1.2.2-1-any.pkg.tar.xz
fi

# Install pyside
if [ ! -f $INSTALL_PATH/lib/pkgconfig/pyside-py2.pc ]; then
  cd $MINGW_PACKAGES_PATH/${MINGW_PREFIX}pyside-qt4 || exit 1
  makepkg-mingw -sLfC
  pacman --force -U ${PKG_PREFIX}pyside-common-1.2.2-1-any.pkg.tar.xz
  pacman --force -U ${PKG_PREFIX}python2-pyside-1.2.2-1-any.pkg.tar.xz
  pacman --force -U ${PKG_PREFIX}python3-pyside-1.2.2-1-any.pkg.tar.xz
fi

# Install SeExpr
if [ ! -f $INSTALL_PATH/lib/libSeExpr.so ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$SEE_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$SEE_TAR -O $SRC_PATH/$SEE_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$SEE_TAR || exit 1
  cd SeExpr-* || exit 1
  mkdir build || exit 1
  cd build || exit 1
  CFLAGS="$BF" CXXFLAGS="$BF" CPPFLAGS="-I${INSTALL_PATH}/include" LDFLAGS="-L${INSTALL_PATH}/lib" cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH || exit 1
  make || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/seexpr || exit 1
  cp ../README ../src/doc/license.txt $INSTALL_PATH/docs/seexpr/ || exit 1
fi

# Install static qt4 for installer
if [ ! -f $INSTALL_PATH/qt4-static/bin/qmake ]; then
  cd $TMP_PATH || exit 1
  QTIFW_CONF="-no-multimedia -no-gif -qt-libpng -no-opengl -no-libmng -no-libtiff -no-libjpeg -static -no-openssl -confirm-license -release -opensource -nomake demos -nomake docs -nomake examples -no-gtkstyle -no-webkit -I${INSTALL_PATH}/include -L${INSTALL_PATH}/lib"

  tar xvf $SRC_PATH/$QT4_TAR || exit 1
  cd qt*4.8* || exit 1
  CFLAGS="$BF" CXXFLAGS="$BF" CPPFLAGS="-I${INSTALL_PATH}/include" LDFLAGS="-L${INSTALL_PATH}/lib" ./configure -prefix $INSTALL_PATH/qt4-static $QTIFW_CONF || exit 1

  # https://bugreports.qt-project.org/browse/QTBUG-5385
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/lib make -j${MKJOBS} || exit 1
  make install || exit 1
fi

# Install setup tools
if [ ! -f $INSTALL_PATH/bin/binarycreator ]; then
  cd $TMP_PATH || exit 1
  git clone $GIT_INSTALLER || exit 1
  cd qtifw || exit 1
  git checkout natron || exit 1
  $INSTALL_PATH/qt4-static/bin/qmake || exit 1
  make -j${MKJOBS} || exit 1
  strip -s bin/*
  cp bin/* $INSTALL_PATH/bin/ || exit 1
fi

if [ ! -z "$TAR_SDK" ]; then
    # Done, make a tarball
    cd $INSTALL_PATH/.. || exit 1
    tar cvvJf $SRC_PATH/Natron-$SDK_VERSION-$SDK.tar.xz Natron-$SDK_VERSION || exit 1

    if [ ! -z "$UPLOAD_SDK" ]; then
    rsync -avz --progress --verbose -e ssh $SRC_PATH/Natron-$SDK_VERSION-$SDK.tar.xz $BINARIES_URL || exit 1
    fi

fi


echo
echo "Natron SDK Done: $SRC_PATH/Natron-$SDK_VERSION-$SDK.tar.xz"
echo
exit 0

