

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


CONTENT_SRC_FILE="data/sample_content.csv"
CONTENT_SURQL_FILE="data/sample_content.surql"




echo "Converting sample content data to SurrealQL format..."
awk '{ line = $0; gsub(/\\/, "\\\\", line); gsub(/"/, "\\\"", line); printf "CREATE sample_content CONTENT {\"content\": \"%s\"};\n", line }' $CONTENT_SRC_FILE > $CONTENT_SURQL_FILE


echo "Truncating content table"
"${SURQL_SQL_CMD[@]}" -d "DELETE FROM sample_content;"

echo "inserting content to database '$CONTENT_SURQL_FILE'..."
"${SURQL_IMPORT_CMD[@]}" $CONTENT_SURQL_FILE

# --- 3. Verification and Cleanup ---
# Get the final row count directly from the database
ROW_COUNT=$("${SURQL_SQL_CMD[@]}" -d "SELECT count() FROM sample_content GROUP ALL;" | jq -r '.[0].result')


echo
echo "✅ Success! Uploaded $(echo $ROW_COUNT | xargs) embeddings into the '$DB_DB' database."

exit 0
