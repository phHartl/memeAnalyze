clean_text<-function(text){
  require(stringr)
  require(stringi)
    url_pattern <- "http[s]?://t\\.co/[^ ]{10}"
    hashtag_pattern <- "#([[:alnum:]]|[_])+"
    mention_pattern <- "@([[:alnum:]]|[_])+"
    strip_RT_pattern<-"RT\\s@([[:alnum:]]|[_])+:"

    # Origin of this file is from Florian Meiers (Uni Regensburg) course about twitter corpus analysis
    #URLs and Mentions removal
    #text<-str_replace_all(text,pattern=url_pattern,replacement = "")
    #text<-str_replace_all(text,pattern=mention_pattern,replacement="")
    #depends on whether you wanna keep hashtags or not
    #text<-str_replace_all(text,pattern="#",replacement="")
  
    #Konvertierung von Umlauten
    text<-stri_replace_all_fixed(text, 
                                  #c("ä", "ö", "ü", "Ä", "Ö", "Ü"),
                                 c("\U00E4","\U00F6","\U00FC","\U00C4","\U00D6","\U00DC"),
                                  c("ae", "oe", "ue", "Ae", "Oe", "Ue"), 
                                  vectorize_all = FALSE)
    #Emoticon removal
    text<-iconv(text, "latin1", "ASCII", sub="")
    
    #Zahlen außer IN Hashtags
    #text<-str_replace_all(text,pattern="\\b\\d+\\b",replacement="")
    
    #Removal: Punctuation characters and Special Characters despite of # 
    text<-str_replace_all(text,pattern="[^[:alnum:]#]",replacement=" ")
    
    #Words with less than 3 chars  außer sie haben #
    #text<-str_replace_all(text,pattern="(?<!#)\\b[a-zA-Z0-9]{1,2}\\b",replacement = "")
    
    #Textlowering
    text<-str_to_lower(text)
    return(text)
}





#check_cleaner<-c("This is a 💁 test #eu string .with @mention and #hashtag but d. u. also with http://www.ur.de !","And another string https://t.co/9aNUY4ZacF with to","we want; to keep #g20 or #r2g but, not 70 or 100 ...")
#clean_text(check_cleaner)




