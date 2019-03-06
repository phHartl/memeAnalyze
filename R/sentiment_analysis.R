library(janeaustenr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(tidytext)
library(reshape2)
library(wordcloud)
#install.packages("wordcloud")

# https://www.tidytextmining.com/sentiment.html


# Import data
#library(readr)
#data_suggest <- read_csv("data_suggest.csv")
#View(data_suggest)


# Loading clean function for using in mutate
source("R/clean_text.R")

# Loading Stopwords
custom_stop_words <- bind_rows(tibble(word = c("miss"), 
                                      lexicon = c("custom")), 
                               stop_words)

custom_stop_words

##############################################

meme_template_texts<-data_suggest%>%
  # meme template topic model / Taking all memes with same meme-template origin 
  group_by(templ_title, meme_id=ID)%>%
  summarise(newDoc=paste0(example_meme_text,collapse=" "))%>%
  ungroup()%>%
  mutate(newDoc=clean_text(newDoc))%>%
  filter(str_count(newDoc)>3)%>%
  group_by(templ_title)%>%
  mutate(index=row_number())%>%
  ungroup()
  

meme_template_words<-meme_template_texts%>%
  unnest_tokens(word, newDoc)


###

# Plot sentiment of each meme template

meme_template_sentiment <- meme_template_words %>%
  inner_join(get_sentiments("bing"))%>%
  count(templ_title, index, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)

ggplot(meme_template_sentiment, aes(index, sentiment, fill = templ_title)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templ_title, ncol = 2, scales = "free_x")



####

# Plot most positive and negative words
meme_template_word_counts <- meme_template_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

meme_template_word_counts %>%
  group_by(sentiment) %>%
  top_n(10) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Contribution to sentiment",
       x = NULL) +
  coord_flip()



###

# Wordclouds
meme_template_words %>%
  # stopwords - to be commented out?
  anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 100))


meme_template_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"),
                   max.words = 100)





