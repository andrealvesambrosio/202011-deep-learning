# Ajuste um modelo para prever se a manchete é sarcástica ou não.
# Use embeddings e lstm
# O banco de dados pode ser obtido com o código abaixo:

# devtools::install_github("henry090/tfaddons")
# tfaddons::install_tfaddons()

library(keras)

df <- readr::read_csv(
  pins::pin("https://storage.googleapis.com/deep-learning-com-r/headlines.csv")
  )

x <- df$headline
y <- df$is_sarcastic

n_palavras <- stringr::str_count(x, pattern = " +") + 1
quantile(n_palavras, c(0.5, 0.75, 0.85, 0.9, 0.95, 0.99, 1))

# Layer para vetorizacao --------

vectorize <- layer_text_vectorization(max_tokens = 10000, output_mode = "int", 
                                      pad_to_max_tokens = TRUE,
                                      output_sequence_length = 40
)

vectorize %>% 
  adapt(x)

vocab <- get_vocabulary(vectorize)

# Definição do modelo -------------

input <- layer_input(shape = 1, dtype = "string")
output <-  input %>%
  vectorize() %>% 
  layer_embedding(input_dim = length(vocab) + 2, output_dim = 32, 
                  mask_zero = TRUE) %>% 
  layer_lstm(units = 256) %>% 
  layer_dense(units = 1, activation = "sigmoid")

model <- keras_model(input, output)

metric_auc <- function() {
  AUC <- tensorflow::tf$keras$metrics$AUC()
  custom_metric("auc", function(y_true, y_pred) {
    AUC(y_true, y_pred)
  })
}

model %>% 
  compile(
    loss = "binary_crossentropy",
    optimizer = "sgd",
    metrics = list(metric_auc())
  )

# ajuste

model %>% 
  fit(matrix(x, ncol = 1), y, validation_split = 0.2, batch_size = 32)

