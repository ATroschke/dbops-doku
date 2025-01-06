#!/bin/bash

echo "Starting Bytebase, Adminer, and MariaDB..."

docker-compose -f docker-compose.mariadb.yml -f docker-compose.adminer.yml -f docker-compose.bytebase.yml up -d

if [ $? -eq 0 ]; then
    echo "All services started successfully."
else
    echo "Failed to start services. Please check the docker-compose files."
fi
