#!/bin/bash

ODOO_VERSION=13
PORT_HTTP=$1
PORT_CHAT=$2
PROJECT_NAME=odoo-$ODOO_VERSION

if [ -z "$PORT_HTTP" ] || [ -z "$PORT_CHAT" ]; then
    echo "Usage: $0 <http_port> <chat_port>"
    exit 1
fi

# Check if the project directory exists
if [ -d "$PROJECT_NAME" ]; then
    echo "Directory $PROJECT_NAME already exists. Please remove it or use a different name."
    exit 1
fi

# Create project directory
mkdir $PROJECT_NAME
cd $PROJECT_NAME

# Create Docker Compose file
cat <<EOF > docker-compose.yml
version: '3'
services:
  web:
    image: odoo:$ODOO_VERSION
    depends_on:
      - db
    ports:
      - "$PORT_HTTP:8069"
      - "$PORT_CHAT:8072"
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons

  db:
    image: postgres:10
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
    volumes:
      - odoo-db-data:/var/lib/postgresql/data

volumes:
  odoo-web-data:
  odoo-db-data:
EOF

# Increase inotify watchers limit
echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start Docker containers
sudo docker-compose up -d

echo "Started Odoo @ http://localhost:$PORT_HTTP | Master Password: odoo | Live chat port: $PORT_CHAT"
