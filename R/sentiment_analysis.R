#install.packages("wordcloud")

library(janeaustenr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(tidytext)
library(reshape2)
library(wordcloud)
library(readr)


# https://www.tidytextmining.com/sentiment.html


# Import data
memes <- read_csv("nodeyourmeme/memes.csv")
View(memes)

# Loading clean function for using in mutate
source("R/clean_text.R")

# Loading Stopwords
custom_stop_words <- bind_rows(tibble(word = c("miss"), 
                                      lexicon = c("custom")), 
                               stop_words)

custom_stop_words

##############################################


meme_template_texts<-memes%>%
  # meme template topic model / Taking all memes with same meme-template origin 
  group_by(templateName, meme_id=rownames(memes))%>%
  summarise(newDoc=paste0(text,collapse=" "))%>%
  ungroup()%>%
  mutate(newDoc=clean_text(newDoc))%>%
  filter(str_count(newDoc)>3)%>%
  group_by(templateName)%>%
  mutate(index=row_number())%>%
  ungroup()
  

meme_template_words<-meme_template_texts%>%
  unnest_tokens(word, newDoc)


###

# Plot sentiment of each meme template

meme_template_sentiment <- meme_template_words %>%
  inner_join(get_sentiments("bing"))%>%
  count(templateName, index, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)

ggplot(meme_template_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  #facet_wrap(~templateName, ncol = 2, scales = "free_y")
  facet_wrap(~templateName, ncol = 4, scales = "free")
  #facet_wrap(~templateName, ncol = 2, scales = "free_x")



####

# Plot most positive and negative words
meme_template_word_counts <- meme_template_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

meme_template_word_counts %>%
  group_by(sentiment) %>%
  top_n(15) %>%
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
  # maybe sorting numbers?
  anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 100))

meme_template_words %>%
  # stopwords - to be commented out?
  #anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 250))


meme_template_words %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"),
                   max.words = 100)





