#!/bin/bash
# Script for installing  wxpython3 (python2) on Ubuntu
# Based on https://aur.archlinux.org/packages/python2-wxpython3 PKGBUILD script
# but modified to install wxpython in user space in separated environment from system python (python3).
# This allows legacy python2 and wxpython3 apps that are not ported to python3 to still function.
# Tested install on Kubuntu 23.04 and 23.10 OK
# Requires pyenv installed (used at setup and install stages). (plus all the other dependencies wxgtk etc)
# Uncomment function calls at botton of script as required.

pkgname=python2-wxpython3
pkgver=3.0.2.0
AURsource="https://aur.archlinux.org/cgit/aur.git/snapshot/python2-wxpython3.tar.gz"
source="https://downloads.sourceforge.net/wxpython/wxPython-src-${pkgver}.tar.bz2"

echo
echo "Uncomment section fucntion calls at the bottom of the script in sequence or as required"

PYVERSION=2.7.18
WXSRCNAME="wxPython-src-$pkgver"
SRC="$HOME/src/python2-wxpython3"
WXSRC="$SRC/$WXSRCNAME"

PREFIX="$HOME/.pyenv/versions/$PYVERSION"
LIBDIR="$PREFIX/lib"
INCLUDEDIR="$PREFIX/include"

pyenv local $PYVERSION
set -e
MYPYVER=$(echo "$(python --version 2>&1)" | awk '{print $2}')

if ! [[ $PYVERSION == $MYPYVER ]]
then
        echo "Wrong pyversion found " $MYPYVER
        exit 1
else
        echo "Python version $PYVERSION"
fi


_configure_opts=(
    --prefix=$PREFIX
    --libdir=$LIBDIR
    --includedir=$INCLUDEDIR
    --disable-monolithic
    --disable-rpath
    --enable-geometry
    --enable-graphics_ctx
    --enable-optimise
    --enable-sound
    --enable-display
    --enable-unicode
    --with-gtk=3
    --with-python=$PREFIX/bin/python
    --with-opengl
    --with-gnomeprint
    --with-sdl
)

get_files() {
    ###install dev files
    sudo apt-get install libgtk-3-dev freeglut3-dev libwxgtk3.2-dev libsdl2-dev

    mkdir -p "$HOME/src"
    # Get build info from AUR
    echo "Downloading $AURsource then extracting in $HOME/src"
    wget $AURsource -P "$HOME/src"
    cd "$HOME/src"

    if [ ! -d $WXSRC ]; then
        tar xvf "python2-wxpython3.tar.gz"
    fi
    # Get wxPython source
    echo "Downloading $source then extracting in $SRC"
    wget $source -P "$SRC"
    cd python2-wxpython3
    tar xvf "$WXSRCNAME.tar.bz2"

}

prepare() {
    ### Patch for python2 - dont need as python2 is python in my env
    ### "Patching shabeng-lines for python2 ..."
    #find . -type f -exec sed -i 's|env python|env python2|' {} \;

    cd "${WXSRC}/wxPython"
    # Fix plot library (FS#42807)
    echo "Applying patch 'fix-plot.patch' ..."
    patch -Np1 -i "$SRC/fix-plot.patch"

    # Fix editra removal (FS#63563)
    echo "Applying patch  'fix-editra-removal.patch' ..."
    patch -Np2 -i "$SRC/fix-editra-removal.patch"
}

config() {
    cd "${WXSRC}"
    ./configure "${_configure_opts[@]}"
}

makeclean() {
    cd "${WXSRC}"
    make clean
}

runmake() {
    cd "${WXSRC}"

    # Old, non-maintained software. Use older C/C++ standard.
    _C_std='gnu++14' # gnu11 # gnu17
    _CXX_std='gnu++14' # gnu++11 # gnu++14 # gnu++17

    # In case a newer C standard is used, warnings are generated which should not be treated as errors.
    _append_to_CFLAGS_after_configure=' -Wno-error=format-security -Wno-error=register -Wno-error=deprecated-declarations \
    -Wno-error=alloc-size-larger-than= -Wno-error=write-strings -Wno-error=return-local-addr -Wno-error=attributes' # Or just use -Wno-error to catch all.
    _append_to_CXXFLAGS_after_configure="${_append_to_CFLAGS_after_configure}"

    CFLAGS+=" -std=${_C_std}"
    CXXFLAGS+=" -std=${_CXX_std}"
    export CFLAGS
    export CXXFLAGS

    CFLAGS+="${_append_to_CFLAGS_after_configure} -std=${_C_std}"
    CXXFLAGS+="${_append_to_CXXFLAGS_after_configure} -std=${_CXX_std}"

    export CFLAGS
    export CXXFLAGS

    make
}

make_install() {
    cd "${WXSRC}"
    make prefix="${PREFIX}/usr" install
}

install_local() {
    cd "${WXSRC}/wxPython"
    pyenv local $PYVERSION

    python setup.py WXPORT=gtk3 UNICODE=1 EP_ADD_OPTS=1 EP_FULL_VER=0 NO_SCRIPTS=1 \
        WX_CONFIG="${WXSRC}/lib/wx/config/gtk3-unicode-3.0 --prefix=${PREFIX} --no_rpath" \
        SYS_WX_CONFIG="${PREFIX}/lib/wx/config/gtk3-unicode-3.0 --version=3.0.2.0 --toolkit=gtk3 --static=no" \
        build_ext --rpath="${PREFIX}/lib" $1
}

#get_files # get and install dev files, patches from AUR, wx source code
#prepare
#config
#makeclean # don't use unless need to
#runmake
#make_install
#install_local 'build'
install_local 'install'
echo "Done!"


