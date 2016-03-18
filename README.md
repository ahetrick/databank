# Databank
Illinois Data Bank institutional data repository

## Installing

### PostgreSQL 9.4.2

### Ruby on Rails 4.2.1

#### RVM

`$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3`

`$ \curl -sSL https://get.rvm.io | bash -s stable`

`$ rvm install 2.2.1`

`$ rvm gemset create fedora4`

#### Install rails

`$ gem install rails`

#### Install Bundler

`$ gem install bundler`

### Databank

#### Check out the code

`$ git clone https://github.com/medusa-project/databank`

`$ cd databank`

#### Install dependent gems

`$ bundle install`

#### Configure the app

`$ cd config`

`$ cp database.default.yml database.yml`

`$ cp databank.default.yml databank.yml`

`$ cp secrets.default.yml secrets.yml`

Edit these as necessary.

#### Create and seed the database 

`$ cd ..`
`$ bundle exec rake db:setup`


#### Run on unicorn server on nix system to support streaming zip file downloads

`$ ./idb_start.sh`

## Integration with archive (Medusa)
### Depends on RabbitMQ Server set up as configured in databank.yml
### Sending messages triggered by actions in databank app
### Getting triggered by cron running a script
#### script example:

`#!/usr/bin/env bash`
`# get_medusa_messages.sh`
`#`
`# ensure a log file`
`logfile=/path/to/log/file" `
`touch logfile`
`#`
`# if using rvm, load RVM into shell session and specify context`
`#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*`
`# rvm use 2.2.1@idb_v1 >> $logfile`
`#`
`# log timestamp`
`echo $(date -u) >> $logfile`
`#`
`# change context to current databank directory`
`cd /path/to/databank/current`
`#`
`# specify environment`
`export RAILS_ENV=[test|development|production]`
`#`
`# run rake task to get and handle messages`
`bundle exec rake medusa:get_medusa_ingest_responses >> $logfile`

#### cron example (hourly):
`0 * * * * /path/to/scripts/get_medusa_messages.sh`

## Automated publishing of embargoed datasets 
### Depends on script triggered by chron 

#### script example:

`#!/usr/bin/env bash`
`# update_pubstate.sh`
`#`
`# ensure a log file`
`logfile=/path/to/log/file`
`touch logfile`
`#`
`# if using rvm, load RVM into shell session and specify context`
`#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*`
`# rvm use 2.2.1@idb_v1 >> $logfile`
`#`
`# log timestamp`
`echo $(date -u) >> $logfile`
`#`
`# change context to current databank directory`
`cd /path/to/databank/current`
`#`
`# specify environment`
`export RAILS_ENV=[test|development|production]`
`#`
`# run rake task to get and handle messages`
`bundle exec rake pub:update_state >> $logfile`
#### cron example (daily @ 1am):
`0 1 * * * /path/to/scripts/update_pubstate.sh`


## Automated email notification
### Depends on script triggered by cron

#### script example:

`#!/usr/bin/env bash`
`# notify.sh`
`#`
`# ensure a log file`
`logfile=/path/to/log/file`
`touch logfile`
`#`
`# if using rvm, load RVM into shell session and specify context`
`#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*`
`# rvm use 2.2.1@idb_v1 >> $logfile`
`#`
`# log timestamp`
`echo $(date -u) >> $logfile`
`#`
`# change context to current databank directory`
`cd /path/to/databank/current`
`#`
`# specify environment`
`export RAILS_ENV=[test|development|production]`
`#`
`# run rake task to get and handle messages`
`bundle exec rake medusa:get_medusa_ingest_responses >> $logfile`

#### cron example (daily @ 2am):
`0 2 * * * /path/to/scripts/notify.sh`





