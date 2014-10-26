#!/bin/bash

set -eu

GPP_OPTIONS="-DHAVE_EIGEN3 -DHAVE_PTHREAD -DHAVE_LINALG_LIB -DHAVE_HDF5 -DHAVE_SSE2 -std=c++11 -I/usr/include/eigen3"

find tests -type f -name "*cc" | grep -vE "tests/unit/base/main_unittest" |
xargs -r readlink -f | grep "^$(readlink -f ./tests/)" | while read sourcefile; do
   if ! g++ $GPP_OPTIONS -I$(dirname "$sourcefile") -Isrc -M "$sourcefile" &>/dev/null; then
       echo "$sourcefile"
   fi
done |xargs -r rm -v

while [[ $(find tests/ -type d -empty |wc -l) -gt 0 ]]; do
   find tests/ -type d -empty -print0 |xargs -r0 rmdir -v 
done
