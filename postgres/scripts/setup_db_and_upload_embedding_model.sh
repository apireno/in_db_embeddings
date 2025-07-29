#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DB_NAME="vector_demo_db"
DB_USER="postgres" # Default PostgreSQL superuser. Change if you have a different user.
DB_HOST="localhost"
DB_PORT="5432"
export PGPASSWORD=root

# File paths
DDL_FILE="surrealdb/db/ddl.sql"
FUNCTIONS_FILE="surrealdb/db/functions.sql"

EMBEDDING_TSV_FILE="data/glove.6B.50d.tsv"
EMBEDDING_SRC_FILE="data/glove.6B.50d.txt"



# --- 1. Download and Prepare GloVe Model ---
echo "--- Checking for embedding model: $EMBEDDING_SRC_FILE ---"

# Check if the final model text file exists
if [ ! -f "$EMBEDDING_SRC_FILE" ]; then
    echo "$EMBEDDING_SRC_FILE missing run the script common/scripts/download_embedding_model.sh first" >&2 # Output error message to stderr
    exit 1 # Exit with an error status of 1
fi


# --- 2. Prepare and Upload Embedding Data ---
echo "--- Preparing embedding model for bulk import ---"
# Convert the space-delimited model file to a tab-separated format suitable for \COPY

awk '{
    word = $1;
    # If the word is a single backslash, escape it by doubling it to \\
    if (word == "\\") {
        word = "\\\\";
    }
    $1 = "";
    gsub(/^[ \t]+|[ \t]+$/, "", $0);
    gsub(/[ \t]+/, ",", $0);
    printf "%s\t[%s]\n", word, $0;
}' "$EMBEDDING_SRC_FILE" > "$EMBEDDING_TSV_FILE"

echo "Conversion complete. Temporary file created at '$EMBEDDING_TSV_FILE'."


# Connect to the default 'postgres' database to perform maintenance.
# This is necessary to terminate connections before dropping the target database.
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres <<-EOSQL
    -- 🤖 Terminate all other connections to the target database
    SELECT 
        pg_terminate_backend(pid) 
    FROM 
        pg_stat_activity 
    WHERE 
        datname = '$DB_NAME' AND pid <> pg_backend_pid();

    -- Drop and recreate the database for a clean slate
    DROP DATABASE IF EXISTS $DB_NAME;
    CREATE DATABASE $DB_NAME;
EOSQL

echo "Database '$DB_NAME' created and all old connections terminated."

# Connect to the new database to run subsequent commands
PSQL_CMD="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"

echo "Creating the pgvector extension..."
$PSQL_CMD -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "Loading DDL from '$DDL_FILE'..."
$PSQL_CMD -f "$DDL_FILE"

echo "Loading functions from '$FUNCTIONS_FILE'..."
$PSQL_CMD -f "$FUNCTIONS_FILE"



echo "--- Uploading embedding data using \COPY ---"

# Use \COPY, which reads from the client filesystem where this script is running.
$PSQL_CMD <<-EOSQL
    TRUNCATE TABLE embedding;
    \COPY embedding(word, embedding) FROM '$EMBEDDING_TSV_FILE' WITH (FORMAT text, DELIMITER E'\t');
EOSQL

# --- 3. Verification and Cleanup ---
# Get the final row count directly from the database
ROW_COUNT=$($PSQL_CMD -t -c "SELECT COUNT(*) FROM embedding;")

# Print final success message (xargs trims whitespace from psql output)
echo
echo "✅ Success! Uploaded $(echo $ROW_COUNT | xargs) embeddings into the '$DB_NAME' database."
