#install.packages("tidytext")
#install.packages("topicmodels")
#install.packages("tm")
#install.packages("tidyverse")
#install.packages("ldatuning")

require("tidyverse")
require("tidytext")
require("topicmodels")
require("tm")

# Import data
#library(readr)
#data_suggest <- read_csv("data_suggest.csv")
#View(data_suggest)


# Loading clean function for using in mutate
source("R/clean_text.R")

# Import data
memes <- read_csv("nodeyourmeme/memes.csv")
memes <- memes%>%filter(!is.na(text))%>%filter(!grepl('.gif', url))

memes_without_text <- memes%>%filter(is.na(text))

#View(memes)

##############################################

# Reading stopwords list


stopwords <- read_csv("R/stopword_lists/stopwords.txt", col_names = FALSE)
stopwords_custom <- read_csv("R/stopword_lists/stopwords_custom.txt", col_names = FALSE)


# Loading Stopwords
custom_stop_words <- bind_rows(tibble(word = c("memegenerator"), 
                                      lexicon = c("custom")), 
                               stop_words)

custom_stop_words
##############################################


prepare_for_LDA<-memes%>%
  # meme template topic model / Taking all memes with same meme-template origin 
  group_by(templateName)%>%
  summarise(newDoc=paste0(text,collapse=" "))%>%
  ungroup()%>%mutate(newDoc=clean_text(newDoc))%>%filter(str_count(newDoc)>3)

prepare_for_LDA_tokens<-prepare_for_LDA%>%
  unnest_tokens(input=newDoc,output=tokens,
                token=stringr::str_split,pattern=" ")                    

# Delete Stopwords
prepare_for_LDA_tokens<-prepare_for_LDA_tokens%>%
                anti_join(stopwords_custom,by=c("tokens"="X1"))

prepare_for_LDA_tokens <- prepare_for_LDA_tokens%>%filter(tokens != "")

# Counting all terms in the documents
prepare_for_LDA_tokens<-prepare_for_LDA_tokens%>%
  count(templateName,tokens,sort=TRUE)

#### Sorting out too often used terms 
prepare_for_LDA_tokens <- prepare_for_LDA_tokens%>%filter(n<150)

#### Sorting out rarely used terms 
prepare_for_LDA_tokens <- prepare_for_LDA_tokens%>%filter(n > 10)

# Convert this tidy df in a docterm-object
tokens_tm<-prepare_for_LDA_tokens%>%
  cast_dtm(templateName,tokens,n)

# Looking at DT-object
tokens_tm

###########################################################

gc()
# We train our topic model with k topics and VEM
memes_topic_model<-LDA(tokens_tm,method = "Gibbs",k=12,control = list(seed = 1234))


# Back-conversion of the LDA-onject via tidy
tidy_memes_topic_model<-tidy(memes_topic_model)

# Getting top 5 terms (= most likely coming from this topic) of each of the Topics
top_terms_memes_topic_model<-tidy_memes_topic_model%>%
  group_by(topic)%>%
  top_n(5, beta)%>%
  ungroup()%>%
  arrange(topic, -beta)


lda_gamma <- tidy(memes_topic_model, matrix = "gamma")
ggplot(lda_gamma, aes(gamma)) +
  geom_histogram() +
  scale_y_log10() +
  labs(title = "Distribution of probabilities for all topics",
       y = "Number of documents", x = expression(gamma))


plot_topics<-top_terms_memes_topic_model%>%
  mutate(term=reorder(term,beta))%>%
  group_by(topic,term)%>%
  arrange(desc(beta))%>%ungroup%>%
  mutate(term = factor(paste(term, topic, sep = "__"), 
                       levels = rev(paste(term, topic, sep = "__"))))


ggplot(data=plot_topics, mapping=aes(term, beta, fill = as.factor(topic))) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  scale_x_discrete(labels = function(x) gsub("__.+$", "", x)) +
  labs(title = "Top terms in each LDA topic",
       x = NULL, y = expression(beta)) +
  facet_wrap(~ topic, ncol = 5, scales = "free")


#https://cran.r-project.org/web/packages/ldatuning/vignettes/topics.html
#Welche Anzahl an Topics ist optimal?

if(FALSE){
  require(ldatuning)
  
  result <- FindTopicsNumber(
    tokens_tm,
    topics = seq(from = 5, to = 20, by = 1),
    metrics = c("Griffiths2004", "CaoJuan2009", "Arun2010", "Deveaud2014"),
    method = "Gibbs",
    control = list(seed = 77),
    mc.cores = 3L,
    verbose = TRUE
  )
  
  FindTopicsNumber_plot(result)
}





