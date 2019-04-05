require(tidyverse)
require(tidytext)
require(RColorBrewer)
require(ggplot2)
theme_set(theme_bw(12))


# Import data
memes <- read_csv("nodeyourmeme/memes.csv")
#View(memes)


ave_words_count <- memes %>%
  group_by(templateName) %>%
  mutate(templateMakros= n()) %>%
  ungroup() %>%
  unnest_tokens(token, text) %>%  # Tokenization
  # anti_join(stop_words, by = "word") %>%     # Excluding stop words             
  # filter(!grepl('[0-9]', word)) %>%         # Excluding numbers
  # left_join(get_sentiments("nrc"), by = "word") %>%
  group_by(templateName, templateMakros) %>%
  summarize(totalTokens= n()) %>%
  mutate(averageTokens=round((totalTokens/templateMakros), digits=0))%>%
  ungroup() %>%
  write.csv(.,file = "R/total_and_average_tokens_in_templates.csv")

most_frequent_words <- memes %>%
  unnest_tokens(token, text) %>%  # Tokenization
  group_by(templateName, token) %>%
  summarize(occurances= n()) %>%
  ungroup()%>%
  group_by(templateName) %>%
  top_n(10) %>%
  write.csv(.,file = "R/10_most_frequent_tokens_in_templates.csv")


