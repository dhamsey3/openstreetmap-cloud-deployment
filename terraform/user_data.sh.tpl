#!/bin/bash
set -e

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

echo "Starting user data script"

# Update the package repository
echo "Updating package repository"
sudo apt-get update -y

# Install dependencies
echo "Installing dependencies"
sudo apt-get install -y curl git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn

# Install Node.js
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

# Install rbenv
echo "Installing rbenv"
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

# Install Ruby and Bundler
echo "Installing Ruby"
rbenv install 3.1.0
rbenv global 3.1.0
ruby -v
gem install bundler

# Install Rails
echo "Installing Rails"
gem update --system
gem install rails -v 6.1
rails -v

# Clone your application repository
echo "Cloning application repository"
cd /home/ubuntu
git clone https://github.com/dhamsey3/openstreetmap-website.git

# Change to the application directory
cd openstreetmap-website

# Install application dependencies
bundle install

# Create Docker configuration files

# Dockerfile
cat <<'EOF_DOCKERFILE' > Dockerfile
FROM ruby:3.1.0
ENV RAILS_ENV production
ENV DATABASE_URL postgresql://${db_username}:${db_password}@db:5432/${db_name}
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /openstreetmap-website
WORKDIR /openstreetmap-website
COPY Gemfile /openstreetmap-website/Gemfile
COPY Gemfile.lock /openstreetmap-website/Gemfile.lock
RUN bundle install
COPY . /openstreetmap-website
RUN bundle exec rake assets:precompile
CMD ["rails", "server", "-b", "0.0.0.0"]
EOF_DOCKERFILE

# docker-compose.yml
cat <<'EOF_DOCKERCOMPOSE' > docker-compose.yml
version: '3.8'
services:
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: ${db_username}
      POSTGRES_PASSWORD: ${db_password}
      POSTGRES_DB: ${db_name}
    volumes:
      - postgres-data:/var/lib/postgresql/data

  web:
    build: .
    command: bundle exec rails s -b '0.0.0.0' -p 3000
    volumes:
      - .:/openstreetmap-website
    ports:
      - "80:3000"
    depends_on:
      - db

volumes:
  postgres-data:
EOF_DOCKERCOMPOSE

# Install Docker
echo "Installing Docker"
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose"
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Start Docker Compose
sudo /home/ubuntu/.docker/cli-plugins/docker-compose up -d

# Install and configure Nginx
echo "Installing and configuring Nginx"
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure Nginx
sudo bash -c 'cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name ${public_ipv4_dns};

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'

sudo systemctl restart nginx

echo "User data script completed"
