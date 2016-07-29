#!/usr/bin/env bash
FILES=/tmp/RackMulti*
for f in $FILES
do
  echo "Removing temporary file $f ..."
  rm -f "$f"
done

bundle exec passenger start -d -e development --nginx-config-template nginx.conf.erb