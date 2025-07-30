#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
DB_DB="vector_demo"
DB_NS="vector_demo"
DB_USER="root" 
DB_PASS="root" 
DB_HOST="0.0.0.0"
DB_PORT="8088"
DB_DIR="rocksdb://~/demo_embeddings"

# File paths
DDL_FILE="surrealdb/db/ddl.surql"
FUNCTIONS_FILE="surrealdb/db/functions.surql"

EMBEDDING_SURQL_FILE="data/glove.6B.50d.surql"
EMBEDDING_SRC_FILE="data/glove.6B.50d.txt"


SURQL_IMPORT_CMD=(
  surreal import
  --conn "http://$DB_HOST:$DB_PORT"
  --user "$DB_USER"
  --pass "$DB_PASS"
  --ns "$DB_NS"
  --db "$DB_DB"
)

SURQL_SQL_CMD=(
  curl
  -X POST
  -u "$DB_USER:$DB_PASS"
  -H "surreal-ns:$DB_NS"
  -H "surreal-db:$DB_DB"
  -H "Accept: application/json"
  "http://$DB_HOST:$DB_PORT/sql"
)


# --- 1. Download and Prepare GloVe Model ---
echo "--- Checking for embedding model: $EMBEDDING_SRC_FILE ---"
# Check if the final model text file exists
if [ ! -f "$EMBEDDING_SRC_FILE" ]; then
    echo "$EMBEDDING_SRC_FILE missing run the script common/scripts/download_embedding_model.sh first" >&2 # Output error message to stderr
    exit 1 # Exit with an error status of 1
fi








  echo  
echo "Loading DDL from '$DDL_FILE'..."
"${SURQL_IMPORT_CMD[@]}" $DDL_FILE

  echo  
echo "Loading functions from '$FUNCTIONS_FILE'..."
"${SURQL_IMPORT_CMD[@]}" $FUNCTIONS_FILE


  echo  
echo "Truncating embedding data table"
"${SURQL_SQL_CMD[@]}" -d "DELETE FROM embedding_model;"


  echo  
echo "Converting embedding data to SurrealQL format..."
awk '{ id = $1; word = $1; gsub(/\\/, "\\\\", id); gsub(/\x60/, "\\\x60", id); gsub(/\\/, "\\\\", word); gsub(/\x27/, "\\\x27", word); printf "CREATE embedding_model:`%s` CONTENT {word: \x27%s\x27, embedding: [", id, word; for(i=2; i<=NF; i++) {printf "%s%s", $i, (i<NF?", ":"")}; print "] };"}' $EMBEDDING_SRC_FILE > $EMBEDDING_SURQL_FILE


  echo  
echo "inserting model to database '$EMBEDDING_SURQL_FILE'..."
"${SURQL_IMPORT_CMD[@]}" $EMBEDDING_SURQL_FILE




  echo  
# --- 3. Verification and Cleanup ---
# Get the final row count directly from the database
ROW_COUNT=$("${SURQL_SQL_CMD[@]}" -d "SELECT count() FROM embedding_model GROUP ALL;" | jq -r '.[0].result')


echo
echo "✅ Success! Uploaded $(echo $ROW_COUNT | xargs) embeddings into the '$DB_DB' database."

exit 0