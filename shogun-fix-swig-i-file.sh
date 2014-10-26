#!/bin/bash

set -eu

ifile="$1"

echo "processing: $ifile"

TEMPFILE=$(mktemp)

grep '[%#]include[[:space:]]*<shogun/' "$ifile" |grep -o "shogun/[^<>]*\.h" |
while read includedfile; do
   if ! test -e "src/$includedfile"; then
      perl -pe "s,^(\s*[%#]include\s*<\s*$includedfile\s*>),/* disabled by $0: \$1 */,g" <"$ifile" >"$TEMPFILE"
      cp "$TEMPFILE" "$ifile"
   fi
done

grep '%template' "$ifile" | perl -pe 's/\s*%template\(\w+\)\s+([^ <>]*)<.*$/$1/;' |
sort |uniq | while read class; do
   CLASSCOUNT=$(grep -ri "template[[:space:]]*class[[:space:]]*$class\W" src/shogun/ |wc -l)
   if [[ $CLASSCOUNT -le 0 ]]; then
      perl -pe "s,^(\s*%template\(\w+\)\s+$class<.*),/* disabled by $0: \$1 */,g" <"$ifile" >"$TEMPFILE"
      cp "$TEMPFILE" "$ifile"
   fi
done
