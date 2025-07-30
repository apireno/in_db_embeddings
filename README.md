
# In-Database Vector Search: A PostgreSQL vs. SurrealDB Comparison

This repository provides a side-by-side comparison of two powerful approaches for performing vector similarity search directly within a database. It implements the same on-the-fly sentence embedding solution in both **PostgreSQL (with the `pgvector` extension)** and **SurrealDB**.

The goal is to demonstrate how each database handles storing embedding models, generating vectors from text, and executing efficient similarity searches.

-----

## The Approaches

This project explores two distinct database philosophies for handling vector workloads:

  * **PostgreSQL + pgvector**: The traditional, battle-tested relational database extended for AI. This approach uses the popular `pgvector` extension to add vector data types, functions, and indexing capabilities to PostgreSQL.

  * **SurrealDB**: A modern, multi-model database with vector search as a native, first-class feature. SurrealDB includes built-in support for vector functions and HNSW indexing without requiring external extensions
-----

## Core Concepts

Both examples are built on the same core concepts:

  * **Model as Data**: The pre-trained **GloVe 6B 50d** word embedding model is stored directly in a database table, mapping words to their corresponding vectors
  * **On-the-Fly Embeddings**: Custom SQL/SurrealQL functions take a string of text, look up the vectors for each word, and compute a single representative vector for the entire sentence (using a mean vector calculation).
  * **Indexed Search**: Both databases use **HNSW (Hierarchical Navigable Small World)** indexes for high-performance similarity searches on the generated vector embeddings.
  * **Sample Data**: The sample content used for searching is from the NLTK Movie Review Corpus, available on [Kaggle](https://www.kaggle.com/datasets/nltkdata/movie-review?select=movie_review.csv).

-----

## Project Structure

```
.
├── data/                   # Shared data
├── common/                   # Shared scripts
│   └── scripts/
│       └── download_embedding_model.sh
├── postgres/                 # PostgreSQL implementation
│   └── db/
│   └── scripts/
└── surrealdb/                # SurrealDB implementation
    └── db/
    └── scripts/
```

-----

## 🚀 Setup and Usage

Follow these steps to set up and run the examples.

### Step 0: Prerequisites

**Shared:**

  * Standard command-line tools like `bash`, `curl`, and `git`.
  * `jq` for parsing JSON in the terminal.

**For the PostgreSQL Example:**

  * A running PostgreSQL server.
  * The `pgvector` extension installed. See instructions [here](https://github.com/pgvector/pgvector).

**For the SurrealDB Example:**

  * The SurrealDB command-line tool. See instructions [here](https://surrealdb.com/docs/installation).

### Step 1: Download Shared Data

First, download the GloVe embedding model that both examples use.

```bash
./common/scripts/download_embedding_model.sh
```

### Step 2: Choose Your Database Example

Run the setup and test scripts for either the PostgreSQL or SurrealDB implementation.

#### A) Running the PostgreSQL Example

Navigate to the `postgres` directory and execute the scripts in order:

1.  **`./postgres/scripts/setup_pgvector`**: Installs the `pgvector` extension.
2.  **`./postgres/scripts/setup_db_and_upload`**: Sets up the database, tables, functions, and uploads the GloVe model.
3.  **`./postgres/scripts/upload_sample_data`**: Ingests the sample movie review content.
4.  **`./postgres/scripts/test_query`**: Prompts for a search term and runs a similarity search.

#### B) Running the SurrealDB Example

All scripts for this example are located in the `surrealdb/scripts` directory. Execute them in order:

1.  **`./surrealdb/scripts/start_surrealdb.sh`**: Starts a local SurrealDB instance.
2.  **`./surrealdb/scripts/setup_db_and_upload_embedding_model.sh`**: Sets up the schema, functions, and uploads the GloVe model.
3.  **`./surrealdb/scripts/upload_sample_data.sh`**: Ingests the sample movie review content.
4.  **`./surrealdb/scripts/test_query.sh`**: Prompts for a search term and runs a similarity search.

-----

## Key Differences & Takeaways

While both solutions achieve the same goal, they highlight different philosophies.

  * **Ease of Setup**: SurrealDB's vector support is built-in, requiring no external extensions. The PostgreSQL approach requires installing and configuring the `pgvector` extension separately.

  * **Automatic Embeddings**: The SurrealDB implementation features **automatic embedding generation**. The `sample_content` table uses `DEFAULT ALWAYS fn::content_to_vector(content)` to compute and store a vector whenever a new record is created, simplifying application logic. In the PostgreSQL version, this step would need to be handled manually or by a trigger.

  * **Query Syntax**: The syntax for vector similarity search is a key differentiator.

    **PostgreSQL (`<->` operator):**

    ```sql
    SELECT
        id,
        content,
        embedding <-> demo_content_to_vector('$ESCAPED_USER_INPUT')::vector AS distance
    FROM
        sample_content
    ORDER BY
        distance
    LIMIT 10;
    ```

    **SurrealDB (`<|...|>` operator):**

    ```surql
    LET $v = fn::content_to_vector('$ESCAPED_USER_INPUT');
    SELECT
        id,
        content,
        vector::distance::euclidean(embedding, $v) AS euclidian_distance
    FROM
        sample_content
    WHERE
        embedding <|10,100|> $v
    ORDER BY
        euclidian_distance
    LIMIT 10;
    ```

-----

## 🙏 References

  * **PostgreSQL**: [https://www.postgresql.org/](https://www.postgresql.org/)
  * **pgvector**: [https://github.com/pgvector/pgvector](https://github.com/pgvector/pgvector)
  * **SurrealDB**: [https://surrealdb.com/](https://surrealdb.com/)
  * **GloVe**: [https://nlp.stanford.edu/projects/glove/](https://nlp.stanford.edu/projects/glove/)
  * **NLTK Movie Review Corpus**: [https://www.kaggle.com/datasets/nltkdata/movie-review](https://www.kaggle.com/datasets/nltkdata/movie-review)