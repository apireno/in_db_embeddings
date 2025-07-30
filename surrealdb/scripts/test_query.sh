

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


SURQL_SQL_CMD=(
  curl
  -X POST
  -u "$DB_USER:$DB_PASS"
  -H "surreal-ns:$DB_NS"
  -H "surreal-db:$DB_DB"
  -H "Accept: application/json"
  "http://$DB_HOST:$DB_PORT/sql"
)


# Prompt the user to enter a sentence.
read -p "Enter a sentence for vector search: " USER_INPUT_SENTENCE

# Escape single quotes in user input for safe SQL execution.
ESCAPED_USER_INPUT=$(echo "$USER_INPUT_SENTENCE" | sed "s/'/''/g")
echo
echo "--- Executing vector search for: \"$USER_INPUT_SENTENCE\" ---"



echo
echo
# This command pipeline executes the query and formats the JSON result into a table.
(
  # 1. Print a tab-separated header for the table.
  echo -e "id\tcontent\tdistance"
  echo  
  # 2. Execute the query. The JSON output is piped to jq.
  "${SURQL_SQL_CMD[@]}" -d @- <<EOF | jq -r '.[1].result[] | [.id, .content, .euclidian_distance] | @tsv'
    LET \$v = fn::content_to_vector('$ESCAPED_USER_INPUT');
    SELECT
        record::id(id) AS id,
        content,
        vector::distance::euclidean(embedding,\$v) AS euclidian_distance
    FROM
        sample_content
    WHERE 
        embedding <|10,100|> \$v
    ORDER BY
        euclidian_distance
    LIMIT 10;
EOF

# 3. The entire output (header and data) is piped to the column command for formatting.
) | column -t -s $'\t'


echo
echo "Script finished."