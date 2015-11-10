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


