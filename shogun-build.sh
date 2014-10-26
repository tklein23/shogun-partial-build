#!/bin/bash
#
# This software is distributed under BSD 3-clause license (see LICENSE file).
#
# Copyright (C) 2014 Thoralf Klein <thoralf@fischlustig.de>
#

set -eu

if [[ $# -lt 1 ]]; then
    echo "usage: $0 build-directory [--skip-tests]"
    echo
    exit -1;
fi

### setup
BUILDDIR="$1"
SKIP_TESTS="${2:-null}"
NUM_CORES=$(nproc 2>/dev/null || echo 2)
NUM_JOBS=$((NUM_CORES+3))

### checking for right directory
test -d src/shogun/ || (echo "ERROR: script must be run in shogun source tree."; exit -1)
test -f src/shogun/base/init.cpp || (echo "ERROR: script must be run in shogun source tree."; exit -1)

### removing old build artifacts (no risk, no fun)
rm -r third_party/libs/gmock/ || :
rm -rf "$BUILDDIR/GoogleMock/" || :
test -d "$BUILDDIR/CMakeFiles/" && rm -r "$BUILDDIR/"
rm -f src/shogun/base/class_list.cpp src/shogun/lib/config.h src/shogun/lib/versionstring.h src/shogun/io/protobuf/*.pb.{cc,h}

### preparing build directoy
mkdir "$BUILDDIR"
cd "$BUILDDIR"
CANONICAL_BUILD_DIR=$(pwd -P)
CANONICAL_PROJECT_DIR=$(dirname $CANONICAL_BUILD_DIR)

cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON \
	-DPythonModular=ON -DJavaModular=OFF -DCMAKE_INSTALL_PREFIX="./install" ..

### building, installing and testing (HACK: due to a bug, locale needs to be C)
time make -j$NUM_JOBS all
time make -j$NUM_JOBS install
[[ $SKIP_TESTS == "--skip-tests" ]] || LC_ALL=C time make ARGS='--output-on-failure' -j$NUM_JOBS test

# activation script for Linux
cat <<HERE >activate-shogun

	export LC_ALL=C # Sorry!  Needed for https://github.com/shogun-toolbox/shogun/issues/2002
	export SHOGUN_INSTALL_DIR="$CANONICAL_BUILD_DIR/install"
	export SHOGUN_DATA_DIR="$CANONICAL_PROJECT_DIR/data"
	export LD_LIBRARY_PATH="\$SHOGUN_INSTALL_DIR/lib"
	export PYTHONPATH="\$SHOGUN_INSTALL_DIR/lib/python2.7/dist-packages/"
	export CLASSPATH="/usr/share/java/jblas.jar:\$SHOGUN_INSTALL_DIR/src/java_modular/shogun.jar:\$CLASSPATH"

HERE

### done!
echo
echo "Welcome to SHOGUN Machine Learning Toolbox -- your installation is ready now."
echo "To setup the needed environment, please run: . $CANONICAL_BUILD_DIR/activate-shogun"
echo
