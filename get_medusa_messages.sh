#!/usr/bin/env bash

rvm use 2.2.1@idb_v1

touch log/get_medusa_messages.log
echo $(date -u) >> log/get_medusa_message.log