# StudyingWeb Culture: Acquisition of a Meme-Corpus and Analysis of textual components

## Abstract

Memes are a popular way to express oneself online in today’s internet culture. Crowd-sourcing 
encyclopedias such as knowyourmeme.com exist solely to document all the different kinds of memes. 
In this paper, we present a novel quantitative approach to meme analysis. First, we gather a corpus 
by using mentioned encyclopedia and applying OCR to extract the textual data contained in memes’ 
images. We used common text mining metrics and techniques to explore our data set via sentiment 
analysis, POS-tagging and topic modelling. Our results show, that the language used in memes differs 
greatly from common literature. Although, memes are used in a lot of different contexts, they all 
follow certain syntactical or pragmatic design patterns. 

## Structure of this repository

The crawling source files for collecting the meme text date can be found in nodeyourmeme directory.


In R-folder, all files concerning the exploration of the gathered corpus are placed.
This includes R files for:
  - word occurances statistics and wordclouds
  - sentiment analysis (standard SA and emotion analysis)
  - topic modeling
  - pre-processing files for text cleaning and stemming/lemmatisation
  
  
Also included are:
  - a folder with used stop word lists
  - a out folder for generated csv, which were used in the paper
  - a img folder containing all relevant images that were generated

