#!/bin/bash
#cloud-config

DOMAIN_NAME="yourdomain.com"
EMAIL="cruzarciniega.d@gmail.com"

# Install necessary packages
apt update -y
apt upgrade -y
apt install -y nginx software-properties-common
add-apt-repository universe -y
apt install -y certbot python3-certbot-dns-route53 ufw

# Enable firewall
ufw allow 'OpenSSH'
ufw allow 'Nginx Full'
ufw --force enable

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Issue certificate using Route 53 DNS challenge
certbot certonly \
  --dns-route53 \
  --non-interactive \
  --agree-tos \
  --email $EMAIL \
  -d $DOMAIN_NAME

# Configure Nginx to use the cert (optional - depends on your config layout)
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    location / {
        proxy_pass http://10.0.10.182:8000/; # Adjust the IP and port as needed
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t && systemctl reload nginx

# Enable auto-renew
systemctl enable certbot.timer
