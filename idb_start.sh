#!/usr/bin/env bash
echo "Removing temp files for failed uploads..."
for f in /tmp/RailsMulipart*
do
  rm -f f
done
echo "Starting unicorn rails server..."
unicorn_rails -c config/unicorn.rb -D