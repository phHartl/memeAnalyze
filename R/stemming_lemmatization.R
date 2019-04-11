#install.packages("koRpus")
#install.packages("SnowballC")
#install.packages("wordnet")
 
# This code is from source:
# http://www.bernhardlearns.com/2017/04/cleaning-words-with-r-stemming.html

library(koRpus)
library(SnowballC)

library(tidyverse) 
library(stringr)

library(wordnet)



if (!exists("haiku_tidy")){
  if (!file.exists("haiku_tidy.RData")){
    res <- tryCatch(download.file("http://bit.ly/haiku_tidy",
                                  "haiku_tidy.RData", mode = "wb"),
                    error=function(e) 1)
  }
  load("haiku_tidy.RData")
}

lemma_unique <- haiku_tidy %>%
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
lemma_tagged <- treetag(lemma_unique$word_clean, treetagger="manual", 
                        format="obj", TT.tknz=FALSE , lang="en",
                        TT.options=list(
                          path="c:/Users/domin/Desktop/Grusch/TreeTagger/", preset="en")
)


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


















