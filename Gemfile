source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use figaro to set environment variables
gem "figaro"

# Use bootstrap for layout framework
gem 'bootstrap-sass', '~> 3.3.4.1'
gem 'font-awesome-sass', '~> 4.3.0'
gem 'autoprefixer-rails'

gem 'haml'
gem 'jquery-datatables-rails'
gem 'jquery-ui-rails'
gem 'highcharts-rails'

gem 'simple_form'

gem 'zipline', path: "vendor/zipline"

# use carrierwave for file upload to temporary location before ingest into fedora
gem 'carrierwave'

# Use ActiveMedusa to interact with Fedora repository
gem 'active-medusa', github: 'medusa-project/active-medusa', tag: '2.0.0'
gem 'httpclient', git: 'git://github.com/medusa-project/httpclient.git'

# Use rsolr to interact with Solr core
gem 'rsolr'

# Use rdf to handle RDF stuff
gem 'rdf'
gem 'rdf-turtle'
gem 'rdf-rdfxml'

gem 'nokogiri'
gem 'equivalent-xml'

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn'

# Use cocoon to helep with nested forms
gem "cocoon"

# Use email validator
gem 'valid_email'

# Use identity strategy to create local accounts for testing
gem 'omniauth-identity'
gem 'omniauth-shibboleth'


# Use canan to restrict what resources a given user is allowed to access
gem 'cancancan'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Use rspec/factory girl/capybara/database cleaner in testing
  gem 'rspec-rails', '~> 3.0.0'
  gem 'factory_girl_rails'
  gem 'capybara'
  gem 'database_cleaner'
end

