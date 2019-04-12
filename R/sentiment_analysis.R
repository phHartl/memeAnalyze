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
#View(memes)
memes <- memes%>%filter(!is.na(text))%>%filter(!grepl('.gif', url))

memes_without_text <- memes%>%filter(is.na(text))

# Loading clean function for using in mutate
source("R/clean_text.R")


# Reading stopwords list

stopwords <- read_csv("R/stopword_lists/stopwords.txt", col_names = FALSE)
stopwords_custom <- read_csv("R/stopword_lists/stopwords_custom.txt", col_names = FALSE)

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

meme_template_words<-meme_template_words%>%
  anti_join(stopwords_custom,by=c("word"="X1"))

meme_template_words<-meme_template_words%>%inner_join(lemma_unique)%>%filter(!is.na(lemma))

# spread of memes inside corpus -> percent of each meme 

meme_occurences <- meme_template_texts%>%group_by(templateName)%>%summarise(n=n()/6797)


###
sentiment_lib = "bing"
#sentiment_lib = "afinn"
#sentiment_lib = "NRC"

# Plot sentiment of each meme template

meme_template_sentiment <- meme_template_words %>%
  inner_join(get_sentiments(sentiment_lib), by=c("lemma" = "word"))%>%
  count(templateName, index, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)

ggplot(meme_template_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  #facet_wrap(~templateName, ncol = 2, scales = "free_y")
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)
  #facet_wrap(~templateName, ncol = 2, scales = "free_x")

# Plot sentiment of a single template
grumpy_cat_sentiment <- dplyr::filter(meme_template_sentiment, templateName =="Grumpy Cat")
ggplot(grumpy_cat_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)

based_god_sentiment <- dplyr::filter(meme_template_sentiment, templateName =="Based God")
ggplot(based_god_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)

bad_luck_brian_sentiment <- dplyr::filter(meme_template_sentiment, templateName =="Bad Luck Brian")
ggplot(bad_luck_brian_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)

ten_guy_sentiment <- dplyr::filter(meme_template_sentiment, templateName =="[10] Guy")
ggplot(ten_guy_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)

philosoraptor_sentiment <- dplyr::filter(meme_template_sentiment, templateName =="Philosoraptor")
ggplot(philosoraptor_sentiment, aes(index, sentiment, fill = templateName)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~templateName, ncol = 4, scales = "free")+
  geom_hline(yintercept=0)


####

# Plot most positive and negative words
meme_template_word_counts <- meme_template_words %>%
  inner_join(get_sentiments(sentiment_lib), by = c("word" = "lemma")) %>%
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




meme_template_words %>%
  inner_join(get_sentiments(sentiment_lib), by = c("lemma" = "word")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("gray20", "gray80"),
                   max.words = 100)

