# install.packages("quanteda") 

library(quanteda)
library(reshape2)
library(wordcloud)
library(readr)
library(gplots)
require(tidyverse)
require(tidytext)
require(RColorBrewer)
require(ggplot2)



# https://www.tidytextmining.com/sentiment.html


# Import data
memes <- read_csv("nodeyourmeme/memes.csv")
#View(memes)
memes <- memes%>%filter(!is.na(text))

memes_without_text <- memes%>%filter(is.na(text))

# Loading clean function for using in mutate
source("R/clean_text.R")


# Reading stopwords list

stopwords <- read_csv("R/stopword_lists/stopwords.txt", col_names = FALSE)
stopwords_custom <- read_csv("R/stopword_lists/stopwords_custom.txt", col_names = FALSE)
stopwords_watermarks <- read_csv("R/stopword_lists/stopwords_watermarks.txt", col_names = FALSE)

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


############


# Occurances


# Word/Token counts
ave_words_count <- memes %>%
  group_by(templateName) %>%
  mutate(templateMakros= n()) %>%
  ungroup() %>%
  unnest_tokens(token, text) %>%  # Tokenization
  anti_join(stopwords_watermarks,by=c("token"="X1")) %>%     # Excluding stop words             
  # filter(!grepl('[0-9]', word)) %>%         # Excluding numbers
  # left_join(get_sentiments("nrc"), by = "word") %>%
  group_by(templateName, templateMakros) %>%
  summarize(totalTokens= n()) %>%
  mutate(averageTokens=round((totalTokens/templateMakros), digits=0))%>%
  ungroup() %>%
  write.csv(.,file = "R/csv-out/total_and_average_tokens_in_templates.csv")

most_frequent_words <- memes %>%
  unnest_tokens(token, text) %>%  # Tokenization
  anti_join(stopwords_watermarks,by=c("token"="X1")) %>%     # Excluding stop words             
  group_by(templateName, token) %>%
  summarize(occurances= n()) %>%
  ungroup()%>%
  group_by(templateName) %>%
  top_n(10) %>%
  write.csv(.,file = "R/csv-out/10_most_frequent_tokens_in_templates.csv")


total_and_average_tokens_in_templates <- read_csv("R/csv-out/total_and_average_tokens_in_templates.csv")
most_frequent_words <- read_csv("R/csv-out/10_most_frequent_tokens_in_templates.csv")


gc()

####
word_freq_per_template <- meme_template_words %>%
  anti_join(stopwords_custom,by=c("word"="X1")) %>%
  group_by(word, templateName) %>%
  summarise(n=n()) %>%
  ungroup() %>%
  group_by(templateName) %>%
  top_n(10)

word_freq_total <- meme_template_words %>%
  anti_join(stopwords,by=c("word"="X1")) %>%
  group_by(word) %>%
  summarise(n=n()) 



############

# Wordclouds

# Package info:
# https://rdrr.io/cran/quanteda/man/textplot_wordcloud.html

# Color variant 
# col <- sapply(seq(0.1, 1, 0.1), function(x) adjustcolor("#1F78B4", x))


words <-meme_template_words %>%
  anti_join(stopwords_custom,by=c("word"="X1"))

word_dfm <- dfm(words$word, remove = stopwords_custom)
textplot_wordcloud(word_dfm, rotation = 0.25, 
                   color = rev(RColorBrewer::brewer.pal(10, "RdBu")))


