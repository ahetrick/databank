[![DOI](https://zenodo.org/badge/12882/medusa-project/databank.svg)](https://zenodo.org/badge/latestdoi/12882/medusa-project/databank)
# Databank

Databank is the Ruby on Rails web application component of Illinois Data Bank, which is a public access repository for research data from the University of Illinois at Urbana-Champaign.

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


#### Solr / Sunspot for search
* Adjust config/sunspot.yml for actual solr implementation

#### Cantaloupe for image processing for previews

* Can be downloaded from [Cantaloupe Getting Started](https://medusa-project.github.io/cantaloupe/get-started.html)
* Find out more at about using the system at [IIIF Image API 2.1.1](http://iiif.io/api/image/2.1/)

## Integration with digital preservation repository @Illinois (Medusa)

The digital preservation component of Illinois Data Bank is supported by integration with the Medusa collection registry. For more information, read the [Medusa FAQ](https://wiki.cites.illinois.edu/wiki/display/LibraryDigitalPreservation/Medusa+FAQ).

Databank exchanges AMPQ messages with Medusa.

* Exchange depends on a RabbitMQ Server set up as configured in databank.default.yml
* Sending messages is triggered by actions in databank app
* Getting messages is triggered by cron running a script

#### script example:

```bash
#!/usr/bin/env bash
# get_medusa_messages.sh
# ensure a log file
logfile=/path/to/log/file" 
touch logfile

# if using rvm, load RVM into shell session and specify context
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
# rvm use 2.2.1@idb_v1 >> $logfile

# log timestamp
echo $(date -u) >> $logfile

# change context to current databank directory
cd /path/to/databank/current

# specify environment
export RAILS_ENV=[test|development|production]

# run rake task to get and handle messages
bundle exec rake medusa:get_medusa_ingest_responses >> $logfile
```

#### cron example (hourly):
`0 * * * * /path/to/scripts/get_medusa_messages.sh`

## Automated publishing of embargoed datasets 
### Depends on script triggered by chron 

#### script example:

```bash
#!/usr/bin/env bash
# update_pubstate.sh
# ensure a log file
logfile=/path/to/log/file
touch logfile

# if using rvm, load RVM into shell session and specify context
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
# rvm use 2.2.1@idb_v1 >> $logfile

# log timestamp
echo $(date -u) >> $logfile

# change context to current databank directory
cd /path/to/databank/current

# specify environment
export RAILS_ENV=[test|development|production]

# run rake task to get and handle messages
bundle exec rake pub:update_state >> $logfile
```

#### cron example (daily @ 1am):
`0 1 * * * /path/to/scripts/update_pubstate.sh`


## Automated email notification
### Depends on script triggered by cron

#### script example:

```bash
#!/usr/bin/env bash
# notify.sh
# ensure a log file
logfile=/path/to/log/file
touch logfile

# if using rvm, load RVM into shell session and specify context
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
# rvm use 2.2.1@idb_v1 >> $logfile

# log timestamp
echo $(date -u) >> $logfile

# change context to current databank directory
cd /path/to/databank/current

# specify environment
export RAILS_ENV=[test|development|production]

# run rake tasks to send notificaiton email
bundle exec rake notify:send_incomplete_1m_all >> $logfile
bundle exec rake notify:send_embargo_approaching_1m_all >> $logfile
bundle exec rake notify:send_embargo_approaching_1w_all >> $logfile
```

#### cron example (daily @ 2am):
`0 2 * * * /path/to/scripts/notify.sh`


## Automated download request address scrubbing
### Depends on script triggered by cron

#### script example:

```bash
#!/usr/bin/env bash
# scrub_download_records.sh
# ensure a log file
logfile=/path/to/log/file
touch logfile

# if using rvm, load RVM into shell session and specify context
#[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
# rvm use 2.2.1@idb_v1 >> $logfile

# log timestamp
echo $(date -u) >> $logfile

# change context to current databank directory
cd /path/to/databank/current

# specify environment
export RAILS_ENV=[test|development|production]

# run rake task to scrub records
bundle exec rake databank:scrub_download_records >> $logfile


#### cron example (daily @ 3am):
`0 3 * * * /path/to/scripts/scrub_download_records_sh`





