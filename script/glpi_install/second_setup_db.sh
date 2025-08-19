#!/bin/bash
set -e

GLPI_DIR="/var/www/html/glpi"
CREDENTIALS_FILE="/root/credentials"
DB_NAME="glpi"
DB_USER="glpi_user"
LOG_FILE="/var/log/user_dbsetup.log"

# Define log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it does not exist
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    chmod 666 "$LOG_FILE"
    log "Log file created: $LOG_FILE"
else
    log "Log file already exists: $LOG_FILE"
fi

log "Starting GLPI database setup process..."

echo "Waiting for MySQL service to be ready..."
for i in {1..30}; do
    if sudo systemctl is-active --quiet mysql || sudo systemctl is-active --quiet mariadb; then
        log "MySQL service is active"
        break
    fi
    if [ $i -eq 30 ]; then
        log "MySQL service failed to start within timeout"
        exit 1
    fi
    sleep 2
done

# Check if GLPI is installed
if [ ! -d "${GLPI_DIR}" ]; then
    log "ERROR: GLPI is not installed. Please run install-glpi.sh first."
    exit 1
fi

# Check if database is already initialized
if [ -f "${CREDENTIALS_FILE}" ]; then
    log "Database credentials file already exists. Checking if database is initialized..."                                      source "${CREDENTIALS_FILE}"                                                                                                                                                                                                                            # Test if database already has GLPI tables                                                                                  if mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME}; SHOW TABLES LIKE 'glpi_users';" 2>/dev/null | grep -q "glpi_users"; then
        log "GLPI database is already initialized. Exiting."
        log "Database credentials are available in: ${CREDENTIALS_FILE}"
        exit 0
    fi
fi

log "Starting GLPI database initialization..."

# Generate MySQL root password
log "Configuring MySQL root password..."
MYSQL_ROOT_PASSWORD=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)

# Secure MySQL installation
log "Securing MySQL installation..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

# Set environment variable for subsequent MySQL operations
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

# Continue with MySQL security hardening
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\\_%';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

# Generate GLPI database password
DB_PASSWORD=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)

# Create GLPI database and user with proper privileges
log "Creating GLPI database and user..."
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${DB_NAME};"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT SELECT ON mysql.time_zone_name TO '${DB_USER}'@'localhost';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

# Test database connection
log "Testing database connection..."
if ! mysql -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME}; SELECT 1;" > /dev/null 2>&1; then
    log "ERROR: Cannot connect to database with GLPI credentials"
    exit 1
fi
log "Database connection test successful"

# Save credentials to file
log "Saving database credentials to ${CREDENTIALS_FILE}..."
sudo tee "${CREDENTIALS_FILE}" > /dev/null << EOF
# MySQL Root Credentials
MYSQL_ROOT_USER=root
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# GLPI Database Credentials
DB_HOST=localhost
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# GLPI Installation Directory
GLPI_DIR=${GLPI_DIR}
EOF

# Enable timezone support for GLPI
log "Enabling timezone support..."
cd "${GLPI_DIR}"
sudo -u www-data php bin/console glpi:database:enable_timezones || log "Warning: Could not enable timezone support"

# Install GLPI database schema
log "Installing GLPI database schema..."

# Check system requirements first
log "Checking system requirements..."
sudo -u www-data php bin/console system:check_requirements

log "Database credentials have been saved to: ${CREDENTIALS_FILE}"
