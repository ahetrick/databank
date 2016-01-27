#!/usr/bin/env bash --login

rvm use 2.2.1@idb_v1
touch log/get_medusa_message.log
echo $(date -u) >> log/get_medusa_message.log