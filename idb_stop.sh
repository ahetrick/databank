#!/usr/bin/env bash
bundle exec passenger stop
FILES=/tmp/RackMulti*
for f in $FILES
do
  echo "Removing temporary file $f ..."
  rm -f "$f"
done

