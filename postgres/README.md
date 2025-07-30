# Postgres Embeddings: On-the-Fly Sentence Embeddings in Your Database

This repository demonstrates how to store word embedding models directly within a PostgreSQL database and generate sentence embeddings on the fly. This approach allows you to perform powerful semantic searches and other NLP tasks without needing to move your data or manage a separate vector search service.

-----

## 🎯 Goal

The primary goal of this project is to show how you can:

  - Store word embedding models in database tables.
  - Calculate sentence embeddings for text blobs in real time.
  - Leverage the power of `pgvector` for efficient similarity searches at scale.

-----

## Prerequisites

Before you begin, you need to have PostgreSQL installed and running. You will also need the `pgvector` extension.

  - **PostgreSQL**: If you don't have it installed, you can find official installation guides [here](https://www.postgresql.org/download/).
  - **pgvector**: The `pgvector` extension enables vector similarity search. Installation instructions are available on the official GitHub repository: [https://github.com/pgvector/pgvector](https://github.com/pgvector/pgvector).

-----

## ✨ Features

  - **pgvector Integration**: Installs and configures the `pgvector` extension for PostgreSQL.
  - **Database Setup**: Creates a dedicated database (`vector_demo_db`) for the demonstration.
  - **Custom SQL Functions**:
      - `demo_mean_vector`: Calculates the mean vector of a set of word vectors.
      - `demo_generate_edgengrams`: Handles out-of-vocabulary (OOV) words using n-grams.
      - `demo_get_sentence_vectors`: Retrieves vectors for a given blob of text.
      - `demo_content_to_vector`: Returns a representative mean vector for a blob of text.
  - **Sample Data**:
      - **Embeddings**: The scripts use the pre-trained **GloVe 6B 50d** model.
      - **Content**: The sample content is from the NLTK Movie Review Corpus, available on [Kaggle](https://www.kaggle.com/datasets/nltkdata/movie-review?select=movie_review.csv).

-----

## ⚙️ How It Works

The core idea is to treat your word embedding model as data. Each word and its corresponding vector are stored in a table. When you want to find the embedding for a sentence, a SQL function processes the text, looks up the vectors for each word, and calculates a representative vector for the entire sentence (in this case, by averaging the word vectors).

By using a **HNSW (Hierarchical Navigable Small World) index** provided by `pgvector`, the similarity search can be performed with high speed and accuracy, even on large datasets.

-----

## 🚀 Setup and Usage

To get started, run the following scripts in order:

0.  **`common/scripts/download_embedding_model`**: Downloads the GloVe embedding model.

1.  **`postgres/scripts/setup_pgvector`**: Installs the `pgvector` extension to your PostgreSQL database.

2.  **`postgres/scripts/setup_db_and_upload`**:

      - Creates the `vector_demo_db` database.
      - Creates the necessary tables and HNSW index.
      - Defines the custom SQL functions.
      - Uploads the GloVe embedding model to a table.

3.  **`postgres/scripts/upload_sample_data`**: Uploads the sample movie review content into the `sample_content` table.

4.  **`postgres/scripts/test_query`**: Runs a sample query to demonstrate a similarity search.

-----

## 🔍 Example Query

The following query finds the 10 most similar content entries to a user-provided input string. The `<->` operator is the Euclidean distance operator from `pgvector`.

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

For example, using the search term "dogs and cats" should yield results similar to this:

```
  id   |                                                   content                                                   |    distance
-------+-------------------------------------------------------------------------------------------------------------+---------------------
 39427 | and puppy dogs' tails .                                                                                     | 0.37405124491216846
 38782 | he also chases cats                                                                                         |  0.4050348521766213
 58019 | do cats bathe themselves regularly ?                                                                        |  0.4231678262333848
 57026 | the psychlos refer to humans as  man animals  but yet dogs are still  dogs  .                               | 0.42556090296606564
 56809 | the animals themselves                                                                                      | 0.42604277392230294
 57665 | it's dog eat dog .                                                                                          | 0.42610469396991857
 57027 | why aren't they  dog animals  ?                                                                             |  0.4323068888025586
 51717 | alien spiders attack them .                                                                                 | 0.44764283777619635
  4886 | the mole rat specialist is delighted to catalog the ways in which these vermin animals behave like insects  |  0.4559699067540398
 47043 | them singing mice                                                                                           | 0.45750013572920156
(10 rows)
```

-----

## 🙏 References and Thank Yous

  - **pgvector**: [https://github.com/pgvector/pgvector](https://github.com/pgvector/pgvector)
  - **GloVe**: [https://nlp.stanford.edu/projects/glove/](https://nlp.stanford.edu/projects/glove/)
  - **NLTK Movie Review Corpus**: [https://www.kaggle.com/datasets/nltkdata/movie-review](https://www.kaggle.com/datasets/nltkdata/movie-review)

A big thank you to the creators and maintainers of these powerful open-source tools and datasets\!