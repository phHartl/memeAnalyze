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
#View(memes)

######################
### Depicting distribution of emotion words usage
# pull emotion words and aggregate by year and emotion terms
emotions <- memes %>% 
  unnest_tokens(word, text) %>%                           
  anti_join(stop_words, by = "word") %>%                  
  filter(!grepl('[0-9]', word)) %>%
  left_join(get_sentiments("nrc"), by = "word") %>%
  filter(!(sentiment == "negative" | sentiment == "positive")) %>%
  group_by(templateName, sentiment) %>%
  summarize( freq = n()) %>%
  mutate(percent=round(freq/sum(freq)*100)) %>%
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

# Terms for all eight emotions types were expressed albeit at variable rates. 
# Looking at the box plot, fear showed an outlier. 

# Besides, anticipation and trust were skewed to the left, whereas joy 
# was skewed to the right. The n= below each box plot indicates the number 
# of observations that contributed to the distribution of the box plot above it.

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

# Emotion words referring to trust and anticipation were slightly over-represented 
# and accounted on average for approximately 32% of all emotion words in all 
# top 16 memes. On the other hand, surprise was the 
# least expressed emotion term and accounted on average for approximately 7% 
# of all emotion terms in all top 16 memes.


### Emotion terms usage over time compared to 40-years averages

# For the figure below, the 40-year averages of each emotion terms shown in 
# the above bar chart were subtracted from the yearly percent emotions for
# any given year. The results were showing higher or lower than average emotion 
# expression levels for the respective years.

## Hi / Low plots compared to the 40-years average
emotions_diff <- emotions  %>%
  left_join(overall_mean_sd, by="sentiment") %>%
  mutate(difference=percent-overall_mean)

ggplot(emotions_diff, aes(x=templateName, y=difference, colour=difference>0)) +
  geom_segment(aes(x=templateName, xend=templateName, y=0, yend=difference),
               size=1.1, alpha=0.8) +
  geom_point(size=1.0) +
  xlab("Emotion Terms") +
  ylab("Net emotion words count (%)") +
  ggtitle("Emotion words expressed in top 16 meme templates") + 
  #theme(legend.position="none") +
  facet_wrap(~sentiment, ncol=4) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.4), legend.position="none")

# Red lines show lower than the average meme template emotion expression levels, while
# blue lines indicate higher than average meme template emotion expression levels.



### Concluding Remarks

# Clearly emotion terms referring to trust and anticipation accounted for approximately 
# 32% of all emotion terms. 
# There were also very limited emotions of suprise (approximately 7%). 









