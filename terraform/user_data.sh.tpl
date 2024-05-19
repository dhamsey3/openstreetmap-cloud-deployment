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
git clone https://github.com/dhamsey3/openstreetmap-website.git
cd openstreetmap-website
bundle install
RAILS_ENV=production DATABASE_URL=postgresql://${db_username}:${db_password}@localhost/${db_name} rails db:migrate

# Configure Nginx as a reverse proxy
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    root /home/ubuntu/openstreetmap-website/public;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Restart Nginx to apply configuration
sudo systemctl restart nginx

# Start the Rails server
RAILS_ENV=production DATABASE_URL=postgresql://${db_username}:${db_password}@localhost/${db_name} rails server -b 127.0.0.1 -p 3000
