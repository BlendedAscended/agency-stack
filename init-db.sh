#!/bin/bash
set -e
set -u

# This script runs inside PostgreSQL container on first start
# Creates databases based on POSTGRES_MULTIPLE_DATABASES variable

# Check if multiple databases are specified
if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    echo "Creating multiple databases: ${POSTGRES_MULTIPLE_DATABASES}"
    
    # Split comma-separated list
    IFS=',' read -ra DBS <<< "$POSTGRES_MULTIPLE_DATABASES"
    
    for db in "${DBS[@]}"; do
        db=$(echo "$db" | xargs)  # Trim whitespace
        echo "Creating database: $db"
        
        # Create database if it doesn't exist (SAFE way)
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
            CREATE DATABASE "$db";
EOSQL
        
        # Grant privileges
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
            GRANT ALL PRIVILEGES ON DATABASE "$db" TO "$POSTGRES_USER";
EOSQL
        
        # Add UUID extension ONLY for windmill database
        if [ "$db" = "windmill" ]; then
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
                CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOSQL
        fi
    done
else
    echo "POSTGRES_MULTIPLE_DATABASES not set, skipping automatic database creation"
fi

echo "Database initialization complete!"
