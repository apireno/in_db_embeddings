#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# GloVe Model Configuration
GLOVE_URL="https://nlp.stanford.edu/data/glove.6B.zip"
GLOVE_ZIP_FILE="data/glove.6B.zip"


EMBEDDING_SRC_FILE="data/glove.6B.50d.txt"
EMBEDDING_TSV_FILE="data/glove.6B.50d.tsv"

# --- 1. Download and Prepare GloVe Model ---
echo "--- Checking for embedding model: $EMBEDDING_SRC_FILE ---"

# Check if the final model text file exists
if [ ! -f "$EMBEDDING_SRC_FILE" ]; then
    echo "Model file not found."
    
    # If the text file doesn't exist, check for the zip file
    if [ ! -f "$GLOVE_ZIP_FILE" ]; then
        echo "Downloading GloVe model from $GLOVE_URL..."
        # Use curl to download the file
        curl -L -o "$GLOVE_ZIP_FILE" "$GLOVE_URL"
        echo "Download complete."
    fi
    
    echo "Unzipping model..."
    # Unzip the archive into the db/ directory, overwriting if necessary
    unzip -o "$GLOVE_ZIP_FILE" -d data/
    echo "Unzip complete."
else
    echo "Found existing model file. Skipping download."
fi

