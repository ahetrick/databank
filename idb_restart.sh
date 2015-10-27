#!/usr/bin/env bash
echo "Removing temp files for failed uploads..."
for f in /tmp/RailsMulipart*
do
  echo f
  rm -f f
done

echo "Killing all unicorn processes..."
for i in `ps awx | grep unicorn | grep -v grep | awk '{print $1;}'`; do
  kill $i
done

echo "Starting unicorn rails server..."
unicorn_rails -c config/unicorn.rb -D