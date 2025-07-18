#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting script..."

apt-get update -y

# Install necessary packages
echo "Installing necessary packages..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl software-properties-common \
    awscli


# Add the Docker GPG key and repository
echo "Adding Docker GPG key and repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

# Install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
apt-get update -y
apt install -y docker-ce docker-ce-cli docker-compose docker.io

# Add ubuntu user to the docker group
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 912262731597.dkr.ecr.us-east-1.amazonaws.com

# Pull the Docker image
echo "Pulling Docker image..."
docker pull 912262731597.dkr.ecr.us-east-1.amazonaws.com/sidereum:latest
docker pull 912262731597.dkr.ecr.us-east-1.amazonaws.com/sidereum:redis
