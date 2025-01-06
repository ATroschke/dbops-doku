@echo off
echo Stopping and removing all containers, networks, and volumes...

docker-compose -f docker-compose.mariadb.yml -f docker-compose.adminer.yml -f docker-compose.flyway.yml -f docker-compose.bytebase.yml down --volumes

if %errorlevel%==0 (
    echo All containers, networks, and volumes have been removed successfully.
) else (
    echo Failed to remove some containers or volumes. Please check your docker-compose setup.
)

echo Removing dangling volumes...
docker volume prune -f
pause
