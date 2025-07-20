#!/bin/bash
set -e

# Update and install NGINX
apt-get update -y
apt-get install -y nginx

# Start and enable NGINX
systemctl start nginx
systemctl enable nginx

# Install Certbot (Snap recommended by Certbot)
apt-get install -y snapd
snap install core && snap refresh core
snap install --classic certbot

# Create symlink for Certbot
ln -s /snap/bin/certbot /usr/bin/certbot