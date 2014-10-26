#!/bin/bash
#
# This software is distributed under BSD 3-clause license (see LICENSE file).
#
# Copyright (C) 2014 Thoralf Klein <thoralf@fischlustig.de>
#

set -eu

if [[ $# -lt 1 ]]; then
    echo "usage: $0 [source files to keep]"
    echo "example: $0 src/shogun/classifier/svm/OnlineLibLinear.h"
    echo
    exit -1;
fi


## setup
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")" #"
SHOGUN_DIR="$(readlink -f .)"


## sanity check that shogun directory is correct
if ! test -e "$SHOGUN_DIR/src/shogun/base/init.h"; then
   echo "shogun directory is not correct.  exiting." 1>&2
   exit -1
fi

cd "$SHOGUN_DIR"
rm -f src/shogun/base/class_list.cpp src/shogun/lib/config.h src/shogun/lib/versionstring.h src/shogun/io/protobuf/*.pb.{cc,h}

SHOGUN_DEPENDENCY_TMPFILE="$(mktemp)"
SHOGUN_DELETE_TMPFILE="$(mktemp)"

"$SCRIPT_DIR"/shogun-get-transitive-dependencies.sh $@ >"$SHOGUN_DEPENDENCY_TMPFILE"


## removing unneeded classes
(
   find src -type f -name "*.h"
   find src -type f -name "*.hpp"
   find src -type f -name "*.c"
   find src -type f -name "*.cc"
   find src -type f -name "*.cpp"
   cat "$SHOGUN_DEPENDENCY_TMPFILE"
) |xargs readlink -f |grep -vE "(sg_print_functions.cpp|class_list.h|config.h)" |sort |uniq -u >"$SHOGUN_DELETE_TMPFILE"

cat "$SHOGUN_DELETE_TMPFILE" |xargs -r rm -v

while [[ $(find src/ -type d -empty |wc -l) -gt 0 ]]; do
   find src/ -type d -empty -print0 |xargs -r0 rmdir -v 
done


## fix unit tests, examples
"$SCRIPT_DIR"/shogun-clear-broken-unittests.sh
"$SCRIPT_DIR"/shogun-clear-broken-examples-cpp.sh


## who needs serialization tests?
test -e src/shogun/io/SerializableAsciiFile.h || echo >tests/unit/io/SerializationAscii_unittest.cc.jinja2
test -e src/shogun/io/SerializableHdf5File.h  || echo >tests/unit/io/SerializationHDF5_unittest.cc.jinja2
test -e src/shogun/io/SerializableJsonFile.h  || echo >tests/unit/io/SerializationJSON_unittest.cc.jinja2
test -e src/shogun/io/SerializableXmlFile.h   || echo >tests/unit/io/SerializationXML_unittest.cc.jinja2


## make SWIG compile again
find src/interfaces/ -type f -name "*.i" |
while read i; do
    "$SCRIPT_DIR"/shogun-fix-swig-i-file.sh "$i";
done


## ...
echo
echo "DONE removing all unneeded classes.  You can build SHOGUN now:"
echo
echo "$SCRIPT_DIR/shogun-build.sh build-quick --skip-tests"
echo
