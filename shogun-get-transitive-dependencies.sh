#!/bin/bash

set -eu

PWD="$(readlink -f .)"

DEPLIST_FILE="$(mktemp)"
DEPLIST_NEW_FILE="$(mktemp)"
DEPLIST_TMP_FILE="$(mktemp)"

GPP_OPTIONS="-DHAVE_EIGEN3 -DHAVE_PTHREAD -DHAVE_LINALG_LIB -DHAVE_HDF5 -DHAVE_SSE2 -std=c++11 -I/usr/include/eigen3"

for sourcefile in $@; do
   if test -e "$sourcefile"; then
      echo "$sourcefile"
   else
      echo "WARNING: sourcefile '$sourcefile' does not exist" 1>&2
   fi
done |xargs -r readlink -f |grep "^$PWD" |sort |uniq >"$DEPLIST_NEW_FILE"

cat "$DEPLIST_NEW_FILE" >"$DEPLIST_FILE"

while [[ "$(wc -l <"$DEPLIST_NEW_FILE")" -gt 0 ]]; do

   echo "current deplist length: $(wc -l <"$DEPLIST_FILE"); adding $(wc -l <"$DEPLIST_NEW_FILE") new entries"

   (
      cat "$DEPLIST_FILE"

      cat "$DEPLIST_NEW_FILE" |perl -pe 's/\.[a-z]+$//g' |while read sourcefile_base; do
         test -e "$sourcefile_base.h"   && echo "$sourcefile_base.h"   || true
         test -e "$sourcefile_base.c"   && echo "$sourcefile_base.c"   || true
         test -e "$sourcefile_base.cc"  && echo "$sourcefile_base.cc"  || true
         test -e "$sourcefile_base.hpp" && echo "$sourcefile_base.hpp" || true
         test -e "$sourcefile_base.cpp" && echo "$sourcefile_base.cpp" || true
      done

      cat "$DEPLIST_NEW_FILE" |sort |uniq |while read sourcefile; do
         if test -e "$sourcefile"; then
            g++ $GPP_OPTIONS -Isrc -MM "$sourcefile" |perl -pe 's,\s*[\n\\]+\s*,,g;' |perl -pe 's,^[^:]+[\s:]*,,; s/\s*$/\n/; s,\s+,\n,g'
         fi
      done
   ) |xargs -r readlink -f |sort |uniq >"$DEPLIST_TMP_FILE"

   cat "$DEPLIST_FILE" "$DEPLIST_TMP_FILE" |grep "^$PWD" |sort |uniq -u >"$DEPLIST_NEW_FILE"
   cat "$DEPLIST_NEW_FILE" >>"$DEPLIST_FILE"

done 1>&2

echo "current deplist length: $(wc -l <"$DEPLIST_FILE")" 1>&2

cat "$DEPLIST_FILE"
rm "$DEPLIST_FILE" "$DEPLIST_NEW_FILE" "$DEPLIST_TMP_FILE"
