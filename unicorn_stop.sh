#!/usr/bin/env bash
for i in `ps awx | grep unicorn | grep -v grep | awk '{print $1;}'`; do
    kill $i
done
