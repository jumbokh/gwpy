#!/bin/bash
#
# build a package with autotools

set -e

builddir=$1
tarball=$2
shift 2

echo "----------------------------------------------------------------------"
echo "Installing from ${tarball}"

# set install target to python prefix
target=`python -c "import sys; print(sys.prefix)"`
echo "Will install into ${target}"
echo "Building into $builddir"

# check for existing file
if [ -f $builddir/.travis-src-file ] && [ "`cat $builddir/.travis-src-file`" == "$tarball $@" ]; then
    echo "Cached build directory found, skippping to make..."
    cd $builddir
else
    # download tarball
    echo "New build requested, downloading tarball..."
    rm -rf $builddir/
    mkdir -p $builddir
    wget $tarball -O `basename $tarball`
    tar -xf `basename $tarball` -C $builddir --strip-components=1
    echo "$tarball $@" > $builddir/.travis-src-file

    # boot and configure
    cd $builddir
    if [ -f ./00boot ]; then
        ./00boot
    elif [ -f ./autogen.sh ]; then
        ./autogen.sh
    fi
    if [ -f ./CMakeLists.txt ]; then
        cmake . -DCMAKE_INSTALL_PREFIX=$target $@
    else
        ./configure --prefix=$target $@
    fi
fi

# configure if the makefile still doesn't exist
if [ ! -f ./Makefile ] && [ -f ./CMakeLists.txt ]; then
    cmake . -DCMAKE_INSTALL_PREFIX=$target $@
elif [ ! -f ./Makefile ]; then
    ./configure --prefix=$target $@
fi

# make and install
make --silent -j2 || { echo "Parallel build failed, retrying serial build..."; make --silent; }
make install --silent

# finish
cd -
echo "----------------------------------------------------------------------"
echo "Successfully installed `basename ${tarball}`"
echo "----------------------------------------------------------------------"
