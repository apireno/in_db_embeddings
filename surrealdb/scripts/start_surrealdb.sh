#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DB_USER="root" 
DB_PASS="root" 
DB_HOST="0.0.0.0"
DB_PORT="8088"
DB_DIR="rocksdb://~/demo_embeddings"
#start the instance of the database if it doesn't exist
if ! surreal start --allow-experimental record_references --user $DB_USER --pass $DB_PASS --bind $DB_HOST:$DB_PORT $DB_DIR; then
    echo "Failed to start SurrealDB instance. Please check if SurrealDB is installed."
    exit 1
fi
exit 0