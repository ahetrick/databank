#!/usr/bin/env bash --login
FILES=/tmp/RackMulti*
for f in $FILES
do
  echo "Removing temporary file $f ..."
  rm -f "$f"
done

echo "Killing all unicorn processes..."
for i in `ps awx | grep unicorn | grep -v grep | awk '{print $1;}'`; do
  kill $i
done

echo "Starting unicorn rails server..."
unicorn -c config/unicorn.rb -D