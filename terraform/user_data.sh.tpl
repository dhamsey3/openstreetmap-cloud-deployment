#!/bin/bash
set -e

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

echo "Starting user data script"

# Update the package repository
echo "Updating package repository"
sudo yum update -y

# Install dependencies
echo "Installing dependencies"
sudo yum install -y curl git zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel libxml2-devel libxslt-devel sqlite-devel nodejs

# Install Node.js
curl -sL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
sudo yum install -y nodejs

# Install Yarn
curl -sS https://dl.yarnpkg.com/rpm/pubkey.gpg | sudo rpm --import -
echo "[yarn]
name=Yarn Repository
baseurl=https://dl.yarnpkg.com/rpm/
enabled=1
gpgcheck=1
gpgkey=https://dl.yarnpkg.com/rpm/pubkey.gpg" | sudo tee /etc/yum.repos.d/yarn.repo
sudo yum install -y yarn

# Install rbenv
echo "Installing rbenv"
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

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
cd /home/ec2-user
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
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose"
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Start Docker Compose
sudo /home/ec2-user/.docker/cli-plugins/docker-compose up -d

# Install and configure Nginx
echo "Installing and configuring Nginx"
sudo amazon-linux-extras install nginx1.12 -y
sudo service nginx start
sudo systemctl enable nginx

# Configure Nginx
sudo bash -c 'cat > /etc/nginx/nginx.conf <<EOF
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
