#!/bin/bash

echo "Stopping and removing all containers, networks, and volumes..."

# Stop and remove containers, networks, and images created by docker-compose files
docker-compose -f docker-compose.mariadb.yml -f docker-compose.adminer.yml -f docker-compose.flyway.yml -f docker-compose.bytebase.yml down --volumes

if [ $? -eq 0 ]; then
    echo "All containers, networks, and volumes have been removed successfully."
else
    echo "Failed to remove some containers or volumes. Please check your docker-compose setup."
fi

# Optionally remove dangling volumes
echo "Removing dangling volumes..."
docker volume prune -f
