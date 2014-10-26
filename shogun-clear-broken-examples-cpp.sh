#!/bin/bash

set -eu

find examples -type f -name "*cpp" | xargs -r readlink -f |
grep "^$(readlink -f ./examples/)" | while read sourcefile; do
   if ! g++ -I$(dirname "$sourcefile") -Isrc -M "$sourcefile" &>/dev/null; then
       echo "$sourcefile"
   fi
done |xargs -r rm -v

while [[ $(find examples/ -type d -empty |wc -l) -gt 0 ]]; do
   find examples/ -type d -empty -print0 |xargs -r0 rmdir -v 
done
