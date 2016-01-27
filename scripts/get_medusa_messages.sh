#!/usr/bin/env bash
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
rvm use 2.2.1@idb_v1 >> /home/databank/shared/log/get_medusa_messages.log

touch /home/databank/shared/log/get_medusa_messages.log
echo $(date -u) >> /home/databank/shared/log/get_medusa_messages.log

