#!/bin/sh

#options:
#TAR_SDK=1 : Make an archive of the SDK when building is done and store it in $SRC_PATH
#UPLOAD_SDK=1 : Upload the SDK tar archive to $REPO_DEST if TAR_SDK=1

source $(pwd)/common.sh || exit 1


if [ "$1" == "32" ]; then
    BIT=32
    TARGET=$TARGET32
    INSTALL_PATH=$INSTALL32_PATH
    CROSS_PREFIX=$CROSS_PREFIX32
elif [ "$1" == "64" ]; then
    BIT=64
    TARGET=$TARGET64
    INSTALL_PATH=$INSTALL64_PATH
    CROSS_PREFIX=$CROSS_PREFIX64
else
    echo "Usage build-sdk.sh <BIT>"
    exit 1
fi


BINARIES_URL=$REPO_DEST/Third_Party_Binaries
SDK=Windows-$TARGET-SDK

if [ -z "$MKJOBS" ]; then
    #Default to 4 threads
    MKJOBS=$DEFAULT_MKJOBS
fi



echo
echo "Building $SDK using with $MKJOBS threads ..."
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
#if [ ! -f ${CROSS_PREFIX}gcc ]; then
#    make gcc || exit 1
#fi

# Install yasm
if [ ! -f $INSTALL_PATH/bin/yasm.exe ]; then
  cd $MXE_INSTALL
  make yasm || exit 1
fi

export PATH=$MXE_INSTALL/usr/bin:$INSTALL_PATH/bin:$PATH


#install gdbm
#if [ ! -f $INSTALL_PATH/lib/libgdbm.a ]; then

    cd $TMP_PATH || exit 1
    if [ ! -f $SRC_PATH/$GDBM_TAR ]; then
        wget $THIRD_PARTY_SRC_URL/$GDBM_TAR -O $SRC_PATH/$GDBM_TAR || exit 1
    fi
    tar xvf $SRC_PATH/$GDBM_TAR || exit 1
    cd gdbm* || exit
    GDBM_PATCHES=$CWD/include/patches/gdbm
    patch -p1 -i ${GDBM_PATCHES}/gdbm-1.10-zeroheaders.patch
    patch -p0 -i ${GDBM_PATCHES}/gdbm-win32-support.patch

    ./configure --host=$TARGET --target=$TARGET  --prefix=$INSTALL_PATH --enable-static --enable-shared --disable-libgdbm-compat || exit 1
#patch -u src/Makefile.in ${GDBM_PATCHES}/LinkAgainstWs32.patch
    make -j${MK_JOBS} || exit 1
    make install || exit 1
#fi

#install db
#if [ ! -f $INSTALL_PATH/lib/libdb.a ]; then

    cd $TMP_PATH || exit 1
    if [ ! -f $SRC_PATH/$DB_TAR ]; then
        wget $THIRD_PARTY_SRC_URL/$DB_TAR -O $SRC_PATH/$DB_TAR || exit 1
    fi
    tar xvf $SRC_PATH/$DB_TAR || exit 1
    cd db* || exit
    DB_PATCHES=$CWD/include/patches/db
    patch -p1 -i ${DB_PATCHES}/mingw.patch
    cd build_unix
    env CFLAGS=$CFLAGS" -DUNICODE -D_UNICODE" CXXFLAGS=$CXXFLAGS" -DUNICODE -D_UNICODE" ../dist/configure --host=$TARGET --target=$TARGET  --prefix=$INSTALL_PATH --enable-static --enable-shared --enable-compat185 --enable-mingw  --enable-cxx --enable-stl  --disable-tcl --disable-replication --docdir='${INSTALL_PATH}/share/doc/db' --disable-rpath --enable-dbm || exit 1
    make LIBSO_LIBS=-lpthread -j${MK_JOBS} || exit 1
    make install || exit 1
#fi

# Install Python2
if [ ! -f $INSTALL_PATH/lib/pkgconfig/python2.pc ]; then

    cd $MXE_INSTALL
    make ncurses || exit 1
    make libffi || exit 1

    cd $TMP_PATH || exit 1
    if [ ! -f $SRC_PATH/$PY2_TAR ]; then
      wget $THIRD_PARTY_SRC_URL/$PY2_TAR -O $SRC_PATH/$PY2_TAR || exit 1
    fi
    tar xvf $SRC_PATH/$PY2_TAR || exit 1
    cd Python-2* || exit 1
    PYTHON_PATCHES=$CWD/include/patches/python2

# these are created by patches
    rm -f Misc/config_mingw Misc/cross_mingw32 Misc/python-config.sh.in Misc/cross_mingw32 Misc/python-config-u.sh.in Python/fileblocks.c

    patch -Np1 -i "$PYTHON_PATCHES"/0000-make-_sysconfigdata.py-relocatable.patch

    patch -p1 -i "$PYTHON_PATCHES"/0100-MINGW-BASE-use-NT-thread-model.patch
    patch -p1 -i "$PYTHON_PATCHES"/0110-MINGW-translate-gcc-internal-defines-to-python-platf.patch
    patch -p1 -i "$PYTHON_PATCHES"/0120-MINGW-use-header-in-lowercase.patch
    patch -p1 -i "$PYTHON_PATCHES"/0130-MINGW-configure-MACHDEP-and-platform-for-build.patch
    patch -p1 -i "$PYTHON_PATCHES"/0140-MINGW-preset-configure-defaults.patch
    patch -p1 -i "$PYTHON_PATCHES"/0150-MINGW-configure-largefile-support-for-windows-builds.patch
    patch -p1 -i "$PYTHON_PATCHES"/0160-MINGW-add-wincrypt.h-in-Python-random.c.patch
    patch -p1 -i "$PYTHON_PATCHES"/0180-MINGW-init-system-calls.patch
    patch -p1 -i "$PYTHON_PATCHES"/0190-MINGW-detect-REPARSE_DATA_BUFFER.patch
    patch -p1 -i "$PYTHON_PATCHES"/0200-MINGW-build-in-windows-modules-winreg.patch
    patch -p1 -i "$PYTHON_PATCHES"/0210-MINGW-determine-if-pwdmodule-should-be-used.patch
    patch -p1 -i "$PYTHON_PATCHES"/0220-MINGW-default-sys.path-calculations-for-windows-plat.patch
    patch -p1 -i "$PYTHON_PATCHES"/0230-MINGW-AC_LIBOBJ-replacement-of-fileblocks.patch

    patch -p1 -i "$PYTHON_PATCHES"/0250-MINGW-compiler-customize-mingw-cygwin-compilers.patch


    patch -p1 -i "$PYTHON_PATCHES"/0270-CYGWIN-issue13756-Python-make-fail-on-cygwin.patch
    patch -p1 -i "$PYTHON_PATCHES"/0290-issue6672-v2-Add-Mingw-recognition-to-pyport.h-to-al.patch
    patch -p1 -i "$PYTHON_PATCHES"/0300-MINGW-configure-for-shared-build.patch
    patch -p1 -i "$PYTHON_PATCHES"/0310-MINGW-dynamic-loading-support.patch
    patch -p1 -i "$PYTHON_PATCHES"/0320-MINGW-implement-exec-prefix.patch
    patch -p1 -i "$PYTHON_PATCHES"/0330-MINGW-ignore-main-program-for-frozen-scripts.patch
    patch -p1 -i "$PYTHON_PATCHES"/0340-MINGW-setup-exclude-termios-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0350-MINGW-setup-_multiprocessing-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0360-MINGW-setup-select-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0370-MINGW-setup-_ctypes-module-with-system-libffi.patch
    patch -p1 -i "$PYTHON_PATCHES"/0380-MINGW-defect-winsock2-and-setup-_socket-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0390-MINGW-exclude-unix-only-modules.patch
    patch -p1 -i "$PYTHON_PATCHES"/0400-MINGW-setup-msvcrt-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0410-MINGW-build-extensions-with-GCC.patch
    patch -p1 -i "$PYTHON_PATCHES"/0420-MINGW-use-Mingw32CCompiler-as-default-compiler-for-m.patch
    patch -p1 -i "$PYTHON_PATCHES"/0430-MINGW-find-import-library.patch
    patch -p1 -i "$PYTHON_PATCHES"/0440-MINGW-setup-_ssl-module.patch
    patch -p1 -i "$PYTHON_PATCHES"/0460-MINGW-generalization-of-posix-build-in-sysconfig.py.patch
    patch -p1 -i "$PYTHON_PATCHES"/0462-MINGW-support-stdcall-without-underscore.patch
    patch -p1 -i "$PYTHON_PATCHES"/0480-MINGW-generalization-of-posix-build-in-distutils-sys.patch
    patch -p1 -i "$PYTHON_PATCHES"/0490-MINGW-customize-site.patch

    patch -p1 -i "$PYTHON_PATCHES"/0500-add-python-config-sh.patch
    patch -p1 -i "$PYTHON_PATCHES"/0510-cross-darwin-feature.patch
    patch -p1 -i "$PYTHON_PATCHES"/0520-py3k-mingw-ntthreads-vs-pthreads.patch
    patch -p1 -i "$PYTHON_PATCHES"/0530-mingw-system-libffi.patch
    patch -p1 -i "$PYTHON_PATCHES"/0540-mingw-semicolon-DELIM.patch
    patch -p1 -i "$PYTHON_PATCHES"/0550-mingw-regen-use-stddef_h.patch
    patch -p1 -i "$PYTHON_PATCHES"/0560-mingw-use-posix-getpath.patch
    patch -p1 -i "$PYTHON_PATCHES"/0565-mingw-add-ModuleFileName-dir-to-PATH.patch
    patch -p1 -i "$PYTHON_PATCHES"/0570-mingw-add-BUILDIN_WIN32_MODULEs-time-msvcrt.patch
    patch -p1 -i "$PYTHON_PATCHES"/0580-mingw32-test-REPARSE_DATA_BUFFER.patch
    patch -p1 -i "$PYTHON_PATCHES"/0590-mingw-INSTALL_SHARED-LDLIBRARY-LIBPL.patch
    patch -p1 -i "$PYTHON_PATCHES"/0600-msys-mingw-prefer-unix-sep-if-MSYSTEM.patch
    patch -p1 -i "$PYTHON_PATCHES"/0610-msys-cygwin-semi-native-build-sysconfig.patch
    patch -p1 -i "$PYTHON_PATCHES"/0620-mingw-sysconfig-like-posix.patch
    patch -p1 -i "$PYTHON_PATCHES"/0630-mingw-_winapi_as_builtin_for_Popen_in_cygwinccompiler.patch
    patch -p1 -i "$PYTHON_PATCHES"/0640-mingw-x86_64-size_t-format-specifier-pid_t.patch
    patch -p1 -i "$PYTHON_PATCHES"/0650-cross-dont-add-multiarch-paths-if-cross-compiling.patch
    patch -p1 -i "$PYTHON_PATCHES"/0660-mingw-use-backslashes-in-compileall-py.patch
    patch -p1 -i "$PYTHON_PATCHES"/0670-msys-convert_path-fix-and-root-hack.patch
    patch -p1 -i "$PYTHON_PATCHES"/0690-allow-static-tcltk.patch
    patch -p1 -i "$PYTHON_PATCHES"/0710-CROSS-properly-detect-WINDOW-_flags-for-different-nc.patch
    patch -p1 -i "$PYTHON_PATCHES"/0720-mingw-pdcurses_ISPAD.patch
    patch -p1 -i "$PYTHON_PATCHES"/0740-grammar-fixes.patch
    patch -p1 -i "$PYTHON_PATCHES"/0750-Add-interp-Python-DESTSHARED-to-PYTHONPATH-b4-pybuilddir-txt-dir.patch
    patch -p1 -i "$PYTHON_PATCHES"/0760-msys-monkeypatch-os-system-via-sh-exe.patch
    patch -p1 -i "$PYTHON_PATCHES"/0770-msys-replace-slashes-used-in-io-redirection.patch
    patch -p1 -i "$PYTHON_PATCHES"/0790-mingw-add-_exec_prefix-for-tcltk-dlls.patch
    patch -p1 -i "$PYTHON_PATCHES"/0800-mingw-install-layout-as-posix.patch
    patch -p1 -i "$PYTHON_PATCHES"/0820-mingw-reorder-bininstall-ln-symlink-creation.patch
    patch -p1 -i "$PYTHON_PATCHES"/0830-add-build-sysroot-config-option.patch
    patch -p1 -i "$PYTHON_PATCHES"/0840-add-builddir-to-library_dirs.patch
    patch -p1 -i "$PYTHON_PATCHES"/0850-cross-PYTHON_FOR_BUILD-gteq-276-and-fullpath-it.patch
    patch -p1 -i "$PYTHON_PATCHES"/0855-mingw-fix-ssl-dont-use-enum_certificates.patch
    patch -p1 -i "$PYTHON_PATCHES"/0860-mingw-build-optimized-ext.patch
    patch -p1 -i "$PYTHON_PATCHES"/0870-mingw-add-LIBPL-to-library-dirs.patch
    patch -p1 -i "$PYTHON_PATCHES"/0910-fix-using-dllhandle-and-winver-mingw.patch

    patch -p1 -i "$PYTHON_PATCHES"/1000-dont-link-with-gettext.patch
    patch -p1 -i "$PYTHON_PATCHES"/1010-ctypes-python-dll.patch
    patch -p1 -i "$PYTHON_PATCHES"/1020-gdbm-module-includes.patch
    patch -p1 -i "$PYTHON_PATCHES"/1030-use-gnu_printf-in-format.patch
    patch -p1 -i "$PYTHON_PATCHES"/1040-install-msilib.patch

    patch -p1 -i "$PYTHON_PATCHES"/2000-distutils-add-windmc-to-cygwinccompiler.patch

    autoreconf -vfi
# Temporary workaround for FS#22322
# See http://bugs.python.org/issue10835 for upstream report
#sed -i "/progname =/s/python/python${_pybasever}/" Python/pythonrun.c

# Enable built-in SQLite module to load extensions (fix FS#22122)
    sed -i "/SQLITE_OMIT_LOAD_EXTENSION/d" setup.py

# FS#23997
    sed -i -e "s|^#.* /usr/local/bin/python|#!/usr/bin/env python2|" Lib/cgi.py

    sed -i "s/python2.3/python2/g" Lib/distutils/tests/test_build_scripts.py \
    Lib/distutils/tests/test_install_scripts.py Tools/scripts/gprof2html.py

    touch Include/graminit.h
    touch Python/graminit.c
    touch Parser/Python.asdl
    touch Parser/asdl.py
    touch Parser/asdl_c.py
    touch Include/Python-ast.h
    touch Python/Python-ast.c
    echo \"\" > Parser/pgen.stamp

# Ensure that we are using the system copy of various libraries (expat, zlib and libffi),
# rather than copies shipped in the tarball
    rm -rf Modules/expat
    rm -rf Modules/zlib
    rm -rf Modules/_ctypes/{darwin,libffi}*

# Workaround for conftest error on 64-bit builds
    export ac_cv_working_tzset=no

    export LIBFFI_INCLUDEDIR='${CROSS_PREFIX}pkg-config libffi --cflags-only-I | sed "s|\-I||g"'

    rm -rf build
    mkdir -p build
    cd build

    env CFLAGS=$CFLAGS" -fwrapv -D__USE_MINGW_ANSI_STDIO=1 -DNDEBUG -I${INSTALL_PATH}/include" CXXFLAGS=$CXXLFLAGS" -fwrapv -D__USE_MINGW_ANSI_STDIO=1 -DNDEBUG -I${INSTALL_PATH}/include" CPPFLAGS=$CPPFLAGS" -I${INSTALL_PATH}/include/ncurses" LDFLAGS=$LDFLAGS" -s -lws_32 -lgdbm" ../configure --prefix=$INSTALL_PATH --build=x86_64-apple-darwin14.4.0  --host=$TARGET --target=$TARGET --enable-shared --with-system-expat --with-system-ffi  --with-threads CC=${CROSS_PREFIX}gcc CXX=${CROSS_PREFIX}g++ AR=${CROSS_PREFIX}ar RANLIB=${CROSS_PREFIX}ranlib STRIP=${CROSS_PREFIX}strip LD=${CROSS_PREFIX}ld AS=${TARGET}-as NM=${CROSS_PREFIX}nm DLLTOOL==${CROSS_PREFIX}dlltool OBJDUMP=${CROSS_PREFIX}objdump RESCOMP=${CROSS_PREFIX}windres  || exit 1
    make -j${MKJOBS} || exit 1
    make install || exit 1
    mkdir -p $INSTALL_PATH/docs/python2 || exit 1
    cp LICENSE $INSTALL_PATH/docs/python2/ || exit 1
fi

# Setup env
export PKG_CONFIG_PATH=$INSTALL_PATH/lib/pkgconfig
export QTDIR=$INSTALL_PATH
export BOOST_ROOT=$INSTALL_PATH
export OPENJPEG_HOME=$INSTALL_PATH
export THIRD_PARTY_TOOLS_HOME=$INSTALL_PATH
export PYTHON_HOME=$INSTALL_PATH
export PYTHON_PATH=$INSTALL_PATH/lib/python2.7
export PYTHON_INCLUDE=$INSTALL_PATH/include/python2.7


# Install boost
if [ ! -f $INSTALL_PATH/lib/libboost_atomic-mt.a ]; then
  cd $MXE_INSTALL
  make boost
fi

# Install jpeg
if [ ! -f $INSTALL_PATH/lib/libjpeg.a ]; then
  cd $MXE_INSTALL
  make jpeg
fi

# Install libpng
if [ ! -f $INSTALL_PATH/lib/pkgconfig/libpng.pc ]; then
  cd $MXE_INSTALL
  make libpng
fi

# Install tiff
if [ ! -f $INSTALL_PATH/lib/pkgconfig/libtiff-4.pc ]; then
  cd $MXE_INSTALL
  make tiff
fi

# Install jasper
if [ ! -f $INSTALL_PATH/lib/libjasper.a ]; then
  cd $MXE_INSTALL
  make jasper
fi

# Install lcms
if [ ! -f $INSTALL_PATH/lib/pkgconfig/lcms2.pc ]; then
  cd $MXE_INSTALL
  make lcms
fi

# Install openjpeg 1.5.2
if [ ! -f $INSTALL_PATH/lib/pkgconfig/libopenjpeg.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$OJPG_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$OJPG_TAR -O $SRC_PATH/$OJPG_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$OJPG_TAR || exit 1
  cd openjpeg-* || exit 1
  OPENJPEG_PATCHES=$CWD/include/patches/openjpeg1.5.2

#Not sure if needed
#patch -Np1 -i $OPENJPEG_PATCHES/cdecl.patch  || exit 1
#  patch -Np1 -i $OPENJPEG_PATCHES/openjpeg-1.5.1_tiff-pkgconfig.patch  || exit 1
# patch -Np1 -i $OPENJPEG_PATCHES/mingw-install-pkgconfig-files.patch  || exit 1
# patch -Np1 -i $OPENJPEG_PATCHES/versioned-dlls-mingw.patch || exit 1
  rm -rf build
  mkdir build
  cd build
  cmake -DCMAKE_TOOLCHAIN_FILE=$INSTALL_PATH/share/cmake/mxe-conf.cmake -DBUILD_SHARED_LIBS=FALSE -DBUILD_TESTING=FALSE .. || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
fi

# Install libraw
if [ ! -f $INSTALL_PATH/lib/pkgconfig/libraw.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$LIBRAW_TAR ]; then
   wget $THIRD_PARTY_SRC_URL/$LIBRAW_TAR -O $SRC_PATH/$LIBRAW_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$LIBRAW_TAR || exit 1
  cd LibRaw* || exit 1
  LIBRAW_PATCHES=$CWD/include/patches/LibRaw
  patch -Np1 -i $LIBRAW_PATCHES/LibRaw_wsock32.patch || exit 1
  patch -Np1 -i $LIBRAW_PATCHES/LibRaw_obsolete-macros.patch || exit 1
  rm -rf build
  mkdir build && cd build
  ../configure --prefix=$INSTALL_PATH --host=$TARGET --build=$BUILD_MACHINE --enable-jasper --enable-lcms --enable-static --disable-shared
  make -j${MKJOBS} || exit 1
  make install
  mkdir -p $INSTALL_PATH/docs/libraw || exit 1
  cp ../README ../COPYRIGHT ../LIC* $INSTALL_PATH/docs/libraw/ || exit 1
fi

# Install openexr
if [ ! -f $INSTALL_PATH/lib/pkgconfig/OpenEXR.pc ]; then
    cd $MXE_INSTALL
    make ilmbase
    make openexr
fi

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
  MAGICK_PATCH=$CWD/include/patches/ImageMagick
  patch -p0< $MAGICK_PATCH/ImageMagick-6.8.10-1.diff || exit 1
  env CFLAGS="-DMAGICKCORE_EXCLUDE_DEPRECATED=1" CXXFLAGS="-I${INSTALL_PATH}/include -DMAGICKCORE_EXCLUDE_DEPRECATED=1"  ./configure --prefix=$INSTALL_PATH --host=$TARGET --build=$BUILD_MACHINE --with-magick-plus-plus=yes --with-quantum-depth=32 --without-dps --without-djvu --without-fftw --without-fpx --without-gslib --without-gvc --without-jbig --without-jpeg --without-lcms --with-lcms2 --without-openjp2 --without-lqr --without-lzma --without-openexr --with-pango --with-png --with-rsvg --without-tiff --without-webp --with-xml --without-zlib --without-bzlib --enable-static --disable-shared --enable-hdri --with-freetype --with-fontconfig --without-x --without-modules --without-threads || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/imagemagick || exit 1
  cp LIC* COP* Copy* Lic* README AUTH* CONT* $INSTALL_PATH/docs/imagemagick/
fi

# Install glew
if [ ! -f $INSTALL_PATH/lib/pkgconfig/glew.pc ]; then
  cd $MXE_INSTALL
  make glew
fi

# Install pixman
if [ ! -f $INSTALL_PATH/lib/pkgconfig/pixman-1.pc ]; then
  cd $MXE_INSTALL
  make pixman
fi

# Install cairo
if [ ! -f $INSTALL_PATH/lib/pkgconfig/cairo.pc ]; then
  cd $MXE_INSTALL
  make cairo
fi

# Install giflib
if [ ! -f $INSTALL_PATH/lib/libgif.a ]; then
    cd $MXE_INSTALL
    make giflib
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
  patch -u CMakeLists.txt ${OCIO_PATCHES}/mingw-w64.patch
  patch -p1 -i ${OCIO_PATCHES}/fix-redefinitions.patch
  patch -p1 -i ${OCIO_PATCHES}/detect-mingw-python.patch

  mkdir build || exit 1
  cd build || exit 1
  cmake -DCMAKE_TOOLCHAIN_FILE=$INSTALL_PATH/share/cmake/mxe-conf.cmake -DOCIO_BUILD_SHARED=OFF -DOCIO_BUILD_STATIC=ON  -DOCIO_BUILD_PYGLUE=OFF -DOCIO_USE_BOOST_PTR=ON -DOCIO_BUILD_APPS=OFF .. || exit 1
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
  OIIO_PATCHES=$CWD/include/OpenImageIO
  patch -p1 -i ${OIIO_PATCHES}/fix-mingw-w64.patch
  patch -p1 -i ${OIIO_PATCHES}/workaround-ansidecl-h-PTR-define-conflict.patch
  patch -p1 -i ${OIIO_PATCHES}/0001-MinGW-w64-include-winbase-h-early-for-TCHAR-types.patch
  patch -p1 -i ${OIIO_PATCHES}/0002-Also-link-to-opencv_videoio-library.patch

  mkdir build || exit 1
  cd build || exit 1
  cmake -DCMAKE_TOOLCHAIN_FILE=$INSTALL_PATH/share/cmake/mxe-conf.cmake -DBUILDSTATIC=ON -DUSE_OPENSSL:BOOL=FALSE -DOPENEXR_HOME=$INSTALL_PATH -DILMBASE_HOME=$INSTALL_PATH -DTHIRD_PARTY_TOOLS_HOME=$INSTALL_PATH -DUSE_QT:BOOL=FALSE -DUSE_TBB:BOOL=FALSE -DUSE_PYTHON:BOOL=FALSE -DUSE_FIELD3D:BOOL=FALSE -DUSE_OPENJPEG:BOOL=TRUE  -DOIIO_BUILD_TESTS=0 -DOIIO_BUILD_TOOLS=0 -DLIBRAW_PATH=$INSTALL_PATH -DBOOST_ROOT=$INSTALL_PATH -DSTOP_ON_WARNING:BOOL=FALSE -DUSE_GIF:BOOL=TRUE -DUSE_FREETYPE:BOOL=TRUE -DFREETYPE_INCLUDE_PATH=$INSTALL_PATH/include -DUSE_FFMPEG:BOOL=FALSE .. || exit 1
  make -j${MKJOBS} || exit 1
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/oiio || exit 1
  cp ../LICENSE ../README* ../CREDITS $INSTALL_PATH/docs/oiio || exit 1
fi

# Install eigen
if [ ! -f $INSTALL_PATH/lib/pkgconfig/eigen3.pc ]; then
  cd $MXE_INSTALL
  make eigen
fi

# Install opencv
if [ ! -f $INSTALL_PATH/lib/pkgconfig/opencv.pc ]; then
  cd $MXE_INSTALL
  make opencv
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

# Install qt
if [ ! -f $INSTALL_PATH/bin/qmake ]; then
  cd $MXE_INSTALL || exit 1
  make qt
fi



# Install shiboken
if [ ! -f $INSTALL_PATH/lib/pkgconfig/shiboken.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$SHIBOK_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$SHIBOK_TAR -O $SRC_PATH/$SHIBOK_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$SHIBOK_TAR || exit 1
  cd shiboken-* || exit 1
  mkdir -p build && cd build || exit 1
  cmake ../ -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH  \
  -DCMAKE_BUILD_TYPE=Release   \
  -DBUILD_TESTS=OFF            \
  -DPYTHON_EXECUTABLE=$INSTALL_PATH/bin/python3 \
  -DPYTHON_LIBRARY=$INSTALL_PATH/lib/libpython3.4.so \
  -DPYTHON_INCLUDE_DIR=$INSTALL_PATH/include/python3.4 \
  -DUSE_PYTHON3=yes \
  -DQT_QMAKE_EXECUTABLE=$INSTALL_PATH/bin/qmake
  make -j${MKJOBS} || exit 1 
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/shibroken || exit 1
  cp ../COPY* $INSTALL_PATH/docs/shibroken/
fi

# Install pyside
if [ ! -f $INSTALL_PATH/lib/pkgconfig/pyside.pc ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$PYSIDE_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$PYSIDE_TAR -O $SRC_PATH/$PYSIDE_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$PYSIDE_TAR || exit 1
  cd pyside-* || exit 1
  mkdir -p build && cd build || exit 1
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF \
  -DQT_QMAKE_EXECUTABLE=$INSTALL_PATH/bin/qmake \
  -DPYTHON_EXECUTABLE=$INSTALL_PATH/bin/python3 \
  -DPYTHON_LIBRARY=$INSTALL_PATH/lib/libpython3.4.so \
  -DPYTHON_INCLUDE_DIR=$INSTALL_PATH/include/python3.4
  make -j${MKJOBS} || exit 1 
  make install || exit 1
  mkdir -p $INSTALL_PATH/docs/pyside || exit 1
  cp ../COPY* $INSTALL_PATH/docs/pyside/ || exit 1
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

# Install SSL (for installer, not working yet)
if [ "$SSL_TAR" != "" ]; then
  cd $TMP_PATH || exit 1
  if [ ! -f $SRC_PATH/$SSL_TAR ]; then
    wget $THIRD_PARTY_SRC_URL/$SSL_TAR -O $SRC_PATH/$SSL_TAR || exit 1
  fi
  tar xvf $SRC_PATH/$SSL_TAR || exit 1
  cd openssl* || exit 1
  CFLAGS="$BF" CXXFLAGS="$BF" ./config --prefix=$INSTALL_PATH || exit 1
  make || exit 1
  make install || exit 1
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

