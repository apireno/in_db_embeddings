Here is a README for your SurrealDB project, structured like your PostgreSQL example and generated from the details in your scripts.

-----

# SurrealDB Embeddings: On-the-Fly Sentence Embeddings in Your Database

This repository demonstrates how to store word embedding models directly within a SurrealDB database and generate sentence embeddings on the fly. This approach allows you to perform powerful semantic searches and other NLP tasks without needing to move your data or manage a separate vector search service.

-----

## 🎯 Goal

The primary goal of this project is to show how you can:

  * Store word embedding models in database tables.
  * Calculate sentence embeddings for text blobs automatically upon ingest.
  * Leverage SurrealDB's native vector functions and indexes for efficient similarity searches at scale.

-----

## Prerequisites

Before you begin, you need to have the SurrealDB command-line tool installed.

  * **SurrealDB**: If you don't have it installed, you can find the official installation guide [here](https://surrealdb.com/docs/installation). The scripts will start a local database instance for you.

-----

## ✨ Features

  * **Native Vector Search**: Utilizes SurrealDB's built-in vector data types and functions for all operations.
  * **Automatic Embeddings**: The `sample_content` table is defined to automatically generate and store a vector embedding for any text inserted into the `content` field.
  * **Custom SurrealQL Functions**:
      * `fn::mean_vector`: Calculates the mean vector from a set of word vectors to represent a sentence. 
      * `fn::retrieve_vectors_for_text_with_oov`: Handles out-of-vocabulary (OOV) words by using an `edgengram` analyzer to find embeddings for parts of unknown words.
      * `fn::content_to_vector`: The main function that takes a string of text and returns a representative vector embedding.
  * **Sample Data**:
      * **Embeddings**: The scripts use the pre-trained **GloVe 6B 50d** model.
      * **Content**: The sample content is from the NLTK Movie Review Corpus, available on [Kaggle](https://www.kaggle.com/datasets/nltkdata/movie-review?select=movie_review.csv).

-----

## ⚙️ How It Works

The core idea is to treat your word embedding model as data. Each word and its corresponding vector are stored in an `embedding_model` table. When you insert text into the `sample_content` table, a `DEFAULT` field definition automatically triggers the `fn::content_to_vector` function to generate a sentence embedding.

For efficient searching, a HNSW (Hierarchical Navigable Small World) index is created on the `embedding` field, allowing for high-speed similarity searches even on large datasets. 

-----

## 🚀 Setup and Usage

To get started, run the following scripts in order:

1.  **`start_surrealdb.sh`**: Starts a local SurrealDB instance using RocksDB for storage.
2.  **`setup_db_and_upload_embedding_model.sh`**:
      * Defines the database schema for the tables.
      * Defines the custom SurrealQL functions.
      * Uploads the GloVe embedding model into the `embedding_model` table.
3.  **`upload_sample_data.sh`**: Ingests the sample movie review content into the `sample_content` table. Embeddings are generated automatically during this step.
4.  **`test_query.sh`**: Prompts for a search term and runs a sample similarity search query.

-----

## 🔍 Example Query

The `test_query.sh` script executes the following query, which finds the 10 most similar content entries to a user-provided input string. The `<|...|>` syntax is SurrealDB's vector distance operator.

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

For example, using the search term "dogs and cats" should yield results similar to this:

```
id                                  content                                                                       euclidian_distance
sample_content:39427                and puppy dogs' tails .                                                         0.37405124491216846
sample_content:38782                he also chases cats                                                             0.4050348521766213
sample_content:58019                do cats bathe themselves regularly ?                                          0.4231678262333848
sample_content:57026                the psychlos refer to humans as  man animals  but yet dogs are still  dogs  . 0.42556090296606564
sample_content:56809                the animals themselves                                                          0.42604277392230294
sample_content:57665                it's dog eat dog .                                                              0.42610469396991857
sample_content:57027                why aren't they  dog animals  ?                                               0.4323068888025586
sample_content:51717                alien spiders attack them .                                                     0.44764283777619635
sample_content:4886                 the mole rat specialist is delighted to catalog the ways in which these vermin animals behave like insects  0.4559699067540398
sample_content:47043                them singing mice                                                               0.45750013572920156
```

-----

## 🙏 References and Thank Yous

  * **SurrealDB**: [https://surrealdb.com/](https://surrealdb.com/)
  * **GloVe**: [https://nlp.stanford.edu/projects/glove/](https://nlp.stanford.edu/projects/glove/)
  * **NLTK Movie Review Corpus**: [https://www.kaggle.com/datasets/nltkdata/movie-review](https://www.kaggle.com/datasets/nltkdata/movie-review)

A big thank you to the creators and maintainers of these powerful open-source tools and datasets\!