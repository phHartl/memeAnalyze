# This code was adapted from: 
# https://datascienceplus.com/parsing-text-for-emotion-terms-analysis-visualization-using-r/
######################

#install.packages("gplots")
library(gplots)
require(tidyverse)
require(tidytext)
require(RColorBrewer)
require(ggplot2)
theme_set(theme_bw(12))


# Import data
memes <- read_csv("nodeyourmeme/memes.csv")

# Remove all entries which contain a GIF-image
memes <- memes%>%filter(!is.na(text))%>%filter(!grepl('.gif', url))

# Remove empty entries not containing any text 
memes_without_text <- memes%>%filter(is.na(text))

#View(memes)

######################
### Depicting distribution of emotion words usage
emotions <- memes %>% 
  unnest_tokens(word, text) %>%                           
  anti_join(stopwords_custom, by=c("word"="X1")) %>%   # Excluding stop words     
  inner_join(lemma_unique)%>%   # joining with lemmata
  filter(!is.na(lemma))%>%      # filter out entries for which no lemma could be found
  filter(!grepl('[0-9]', word)) %>%   # ignore numbers
  left_join(get_sentiments("nrc"), by = c("lemma" = "word")) %>%    # sentiment comparison 
  filter(!(sentiment == "negative" | sentiment == "positive")) %>%  # ignore positive and negativ categories; we interested in emotions here
  group_by(templateName, sentiment) %>%
  summarize( freq = n()) %>%
  mutate(percent=round(freq/sum(freq)*100)) %>%   # calculate percentage of sentiment contribution
  select(-freq) %>%
  ungroup()

# need to convert the data structure to a wide format
emo_box = emotions %>%
  spread(sentiment, percent, fill=0) %>%
  ungroup()

### color scheme for the box plots (This step is optional)
cols  <- colorRampPalette(brewer.pal(7, "Set3"), alpha=TRUE)(8)
boxplot2(emo_box[,c(2:9)], 
         col=cols, 
         lty=1, 
         shrink=0.8, 
         textcolor="red",        
         xlab="Emotion Terms", 
         ylab="Emotion words count (%)", 
         main="Distribution of emotion words count in top 16 meme templates")

########################



### Average emotion words expression using bar charts with error bars
# calculate overall averages and standard deviations for each emotion term
overall_mean_sd <- emotions %>%
  group_by(sentiment) %>%
  summarize(overall_mean=mean(percent), sd=sd(percent))

# draw a bar graph with error bars
ggplot(overall_mean_sd, aes(x = reorder(sentiment, -overall_mean), y=overall_mean)) +
  geom_bar(stat="identity", fill="darkgreen", alpha=0.7) + 
  geom_errorbar(aes(ymin=overall_mean-sd, ymax=overall_mean+sd), width=0.2,position=position_dodge(.9)) +
  xlab("Emotion Terms") +
  ylab("Emotion words count (%)") +
  ggtitle("Emotion words expressed in top 16 meme templates") + 
  theme(axis.text.x=element_text(angle=45, hjust=1)) +
  coord_flip( )


emotions_diff <- emotions  %>%
  left_join(overall_mean_sd, by="sentiment") %>%
  mutate(difference=percent-overall_mean)


# Overview of sentiment contribution of every meme template to each emotion category
# Red lines show lower than the average meme template emotion expression levels, while
# blue lines indicate higher than average meme template emotion expression levels.
ggplot(emotions_diff, aes(x=templateName, y=difference, colour=difference>0)) +
  geom_segment(aes(x=templateName, xend=templateName, y=0, yend=difference),
               size=1.1, alpha=0.8) +
  geom_point(size=1.0) +
  xlab(" ") + # "Emotion Terms"
  ylab("Net emotion words count (%)") +
  ggtitle("Emotion words expressed in top 16 meme templates") + 
  #theme(legend.position="none") +
  facet_wrap(~sentiment, ncol=4) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.4), legend.position="none")



# Print quantiles
quantile(emo_box$fear)





