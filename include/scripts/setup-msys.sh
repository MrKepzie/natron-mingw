#!/bin/sh
# Installs the required Msys/Mingw packages to build Natron and plug-ins

source $(pwd)/common.sh || exit 1

if [ "$1" == "32" ]; then
PKG_PREFIX=$PKG_PREFIX32
else
PKG_PREFIX=$PKG_PREFIX64
fi

#Update database
pacman --noconfirm  -Syu

PKG_INSTALL_OPS=--noconfirm -S
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}toolchain
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}yasm
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}gdbm
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}db
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}python2
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}boost
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}qt4
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}libjpeg-turbo
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}libpng
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}libtiff
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}giflib
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}lcms2
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}openjpeg
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}LibRaw
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}ilmbase
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}openexr
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}glew
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}pixman
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}cairo
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}openssl
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}freetype
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}fontconfig
pacman $PKG_INSTALL_OPS ${PKG_PREFIX}eigen3