#!/usr/bin/env bash
FILES=/tmp/RackMulti*
for f in $FILES
do
  echo "Removing temporary file $f ..."
  rm -f "$f"
done
echo "Starting unicorn rails server..."
unicorn_rails -c config/unicorn.rb -D