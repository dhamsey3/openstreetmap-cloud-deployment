#!/bin/bash
sudo apt-get update
sudo apt-get install -y ruby-full
sudo apt-get install -y build-essential
sudo apt-get install -y libssl-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y libreadline-dev
sudo apt-get install -y libyaml-dev
sudo apt-get install -y libsqlite3-dev
sudo apt-get install -y sqlite3
sudo apt-get install -y libxml2-dev
sudo apt-get install -y libxslt1-dev
sudo apt-get install -y libcurl4-openssl-dev
sudo apt-get install -y software-properties-common
sudo apt-get install -y libffi-dev
sudo apt-get install -y git
sudo apt-get install -y postgresql postgresql-contrib
sudo apt-get install -y nginx
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo gem install rails
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create PostgreSQL user and database
sudo -u postgres psql -c "CREATE USER ${db_username} WITH PASSWORD '${db_password}';"
sudo -u postgres psql -c "CREATE DATABASE ${db_name} WITH OWNER ${db_username};"

# Clone and setup the application
cd /home/ubuntu
git clone https://github.com/openstreetmap/openstreetmap-website.git
cd openstreetmap-website
bundle install
RAILS_ENV=production DATABASE_URL=postgresql://${db_username}:${db_password}@localhost/${db_name} rails db:migrate
RAILS_ENV=production DATABASE_URL=postgresql://${db_username}:${db_password}@localhost/${db_name} rails server -b 0.0.0.0
