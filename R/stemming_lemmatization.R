#install.packages("koRpus")
#install.packages("SnowballC")
#install.packages("wordnet")

# This code is from source:
# http://www.bernhardlearns.com/2017/04/cleaning-words-with-r-stemming.html

#install.packages('rJava')
library(rJava)
library(koRpus)
#Install english language
#install.koRpus.lang("en")
library(koRpus.lang.en)
library(SnowballC)

library(tidyverse) 
library(stringr)
library(dplyr)
library(wordnet)



if (!exists("haiku_tidy")){
  if (!file.exists("haiku_tidy.RData")){
    res <- tryCatch(download.file("http://bit.ly/haiku_tidy",
                                  "haiku_tidy.RData", mode = "wb"),
                    error=function(e) 1)
  }
  load("haiku_tidy.RData")
}

lemma_unique <- meme_template_words %>%
  select(word) %>%
  mutate(word_clean = str_replace_all(word,"\u2019s|'s","")) %>%
  mutate(word_clean = ifelse(str_detect(word_clean,"[^[:alpha:]]"),NA,word_clean)) %>%
  filter(!duplicated(word_clean)) %>%
  filter(!is.na(word_clean)) %>%
  arrange(word)

lemma_unique<-lemma_unique %>%
  mutate(word_stem = wordStem(word_clean, language="english"))


#### Stemming
lemma_unique<-lemma_unique %>%
  mutate(word_stem = wordStem(word_clean, language="english"))


#### Lemmatization
# therefore, TreeTager has to be installed!:
# http://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/#Windows
#lemma_tagged <- treetag(lemma_unique$word_clean, treetagger="manual", 
#                        format="obj", TT.tknz=FALSE , lang="en",
#                        TT.options=list(
#                          path="~/Downloads/TreeTagger", preset = "en")
#)
# c:/Users/domin/Desktop/Grusch/TreeTagger/

#Should use a predefined config instead for better results -> we would need a proper lexcion

lemma_tagged <- treetag(lemma_unique$word_clean, format = "obj",
                        treetagger="/home/philipp/Downloads/TreeTagger/cmd/tree-tagger-english", lang="en")
#C:/Users/domin/Desktop/Grusch/TreeTagger/

lemma_tagged_tbl <- tbl_df(lemma_tagged@TT.res)

lemma_unique <- lemma_unique %>% 
  left_join(lemma_tagged_tbl %>%
              filter(lemma != "<unknown>") %>%
              select(token, lemma, wclass),
            by = c("word_clean" = "token")
  ) %>%
  arrange(word)





#### Replacing with more common synonym

synonyms_failsafe <- function(word, pos){
  tryCatch({
    syn_list = list(syn=synonyms(word, toupper(pos)))
    if (length(syn_list[["syn"]])==0) syn_list[["syn"]][[1]] = word
    syn_list
  },
  error = function(err){
    return(list(syn=word))
  })
}


lemma_unique <- lemma_unique %>%
  mutate(word_synonym = map2(lemma, wclass,synonyms_failsafe))


if (!exists("word_frequencies")){
  if (!file.exists("lemma.num")){
    res <- tryCatch(download.file("http://www.kilgarriff.co.uk/BNClists/lemma.num",
                                  "lemma.num", mode = "wb"),
                    error=function(e) 1)
  }
  word_frequencies <- 
    readr::read_table2("lemma.num",
                       col_names=c("sort_order", "frequency", "word", "wclass"))
  
  # harmonize wclass types with existing
  word_frequencies <- word_frequencies %>%
    mutate(wclass = case_when(.$wclass == "conj" ~ "conjunction",
                              .$wclass == "adv" ~ "adverb",
                              .$wclass == "v" ~ "verb",
                              .$wclass == "det" ~ "determiner",
                              .$wclass == "pron" ~ "pronoun",
                              .$wclass == "a" ~ "adjective",
                              .$wclass == "n" ~ "noun",
                              .$wclass == "prep" ~ "preposition")
    )
  
}

frequent_synonym <- function(syn_list, pos=NA, word_frequencies){
  syn_vector <- syn_list$syn
  
  if (!is.na(pos) && pos %in% unique(word_frequencies$wclass)){
    syn_tbl <- tibble(word = syn_vector,
                      wclass = pos)
  } else {
    syn_tbl <- tibble(word = syn_vector)
  }
  
  suppressMessages(
    syn_tbl <- syn_tbl %>%
      inner_join(word_frequencies) %>%
      arrange(frequency)
  )
  
  return(ifelse(nrow(syn_tbl)==0,NA,syn_tbl$word[[1]]))
}

lemma_unique <- lemma_unique %>%
  mutate(synonym = map_chr(word_synonym, frequent_synonym, 
                           word_frequencies = word_frequencies)) %>%
  mutate(synonym = ifelse(is.na(synonym), lemma, synonym))

write.csv(lemma_unique[1:5],file = "R/csv-out/lemmatisation.csv")

n_orig <- lemma_unique %>% 
  inner_join(tidytext::get_sentiments("bing"),
             by=c("word" = "word")) %>% 
  nrow()

n_orig

n_stem <- lemma_unique %>% 
  inner_join(tidytext::get_sentiments("bing"),
             by=c("word_stem" = "word")) %>% 
  nrow()

n_stem

n_clean <- lemma_unique %>% 
  inner_join(tidytext::get_sentiments("bing"),
             by=c("word_clean" = "word")) %>% 
  nrow()

n_clean

n_lemma <- lemma_unique %>% 
  inner_join(tidytext::get_sentiments("bing"),
             by=c("lemma" = "word")) %>% 
  nrow()

n_lemma

n_synonym <- lemma_unique %>% 
  inner_join(tidytext::get_sentiments("bing"),
             by=c("synonym" = "word")) %>% 
  nrow()

n_synonym


wclasses <- lemmatisation %>%
  group_by(wclass) %>%
  summarise(n = n()) %>%
  arrange(desc(n)) %>%
  write.csv(.,file = "R/csv-out/word_classes.csv")

