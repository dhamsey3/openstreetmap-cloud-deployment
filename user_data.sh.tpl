#!/bin/bash
set -e

# Redirect all output to a log file
exec > /var/log/user-data.log 2>&1

echo "Starting user data script"

# Update the package repository
echo "Updating package repository"
sudo yum update -y

# Install Docker
echo "Installing Docker"
sudo amazon-linux-extras install docker -y

# Start Docker service
echo "Starting Docker service"
sudo service docker start

# Ensure Docker starts on boot
echo "Enabling Docker to start on boot"
sudo systemctl enable docker

# Install Docker Compose
echo "Installing Docker Compose"
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.11.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Install Git
echo "Installing Git"
sudo yum install git -y

# Clone your application repository
echo "Cloning application repository"
cd /home/ec2-user
git clone git@github.com:dhamsey3/openstreetmap-website.git

# Change to the application directory
cd openstreetmap-website

# Create Docker configuration files

# Dockerfile
cat <<'EOF_DOCKERFILE' > Dockerfile
FROM ruby:2.7
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

# Start Docker Compose
echo "Starting Docker Compose"
sudo /home/ec2-user/.docker/cli-plugins/docker-compose up -d

echo "User data script completed"
