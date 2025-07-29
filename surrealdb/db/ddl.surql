


REMOVE TABLE IF EXISTS embedding_model;
DEFINE TABLE embedding_model TYPE NORMAL SCHEMAFULL;
DEFINE FIELD word ON embedding_model TYPE string;
DEFINE FIELD embedding ON embedding_model TYPE array<float>;


REMOVE TABLE IF EXISTS sample_content;
DEFINE TABLE sample_content TYPE NORMAL SCHEMAFULL;
DEFINE FIELD content ON sample_content TYPE string;
DEFINE FIELD embedding ON sample_content TYPE option<array<float>> DEFAULT ALWAYS fn::content_to_vector(content);


DEFINE INDEX IF NOT EXISTS embedding_index ON sample_content FIELDS embedding HNSW DIMENSION 50 M 32 EFC 300;


DEFINE ANALYZER IF NOT EXISTS large_name_analyzer TOKENIZERS class FILTERS lowercase, ascii, edgengram(2, 10);