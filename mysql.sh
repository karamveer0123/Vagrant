#!/bin/bash
yum install git -y

DATABASE_PASS='admin123'

echo "=================Install MySQL Server================="
echo "Installing MySQL Server..."
sudo dnf -y install mysql-server

echo "Start and enable MySQL service"
echo "Starting MySQL service..."
sudo systemctl start mysqld
sudo systemctl enable mysqld

echo "Cloning project repository..."
cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git

echo "Setting MySQL root password..."
# Secure MySQL installation (including password setting)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DATABASE_PASS}'"

echo "Removing unwanted MySQL users and databases..."
sudo mysql -u root -p"${DATABASE_PASS}" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"${DATABASE_PASS}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"${DATABASE_PASS}" -e "FLUSH PRIVILEGES"

echo "Creating database and setting up permissions..."
sudo mysql -u root -p"${DATABASE_PASS}" -e "CREATE DATABASE accounts"

# Create users and set their passwords
sudo mysql -u root -p"${DATABASE_PASS}" -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '${DATABASE_PASS}'"
sudo mysql -u root -p"${DATABASE_PASS}" -e "CREATE USER 'admin'@'%' IDENTIFIED BY '${DATABASE_PASS}'"

sudo mysql -u root -p"${DATABASE_PASS}" -e "ALTER USER 'admin'@'localhost' IDENTIFIED BY '${DATABASE_PASS}'"
sudo mysql -u root -p"${DATABASE_PASS}" -e "ALTER USER 'admin'@'%' IDENTIFIED BY '${DATABASE_PASS}'"

sudo mysql -u root -p"${DATABASE_PASS}" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost'"
sudo mysql -u root -p"${DATABASE_PASS}" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%'"

echo "Restoring database from dump..."
sudo mysql -u root -p"${DATABASE_PASS}" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql

echo "Flushing privileges..."
sudo mysql -u root -p"${DATABASE_PASS}" -e "FLUSH PRIVILEGES"

echo "Restarting MySQL service..."
sudo systemctl restart mysqld

