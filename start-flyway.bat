@echo off
echo Starting Flyway, Adminer, and MariaDB...

docker-compose -f docker-compose.mariadb.yml -f docker-compose.adminer.yml -f docker-compose.flyway.yml up -d

if %errorlevel%==0 (
    echo All services started successfully.
) else (
    echo Failed to start services. Please check the docker-compose files.
)
pause