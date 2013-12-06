load('out/data1.Rd')

# remove punctuation
descr <- gsub('\\(|\\)|"|;|&|#|\\.|:|\'|\\\\n|,|/', ' ', tolower(c(as.character(d$description), as.character(d.test$description))))

# remove stopwords
stop.words <- names(read.csv('../stop_words.csv'))
stop.words <- c(stop.words, '')

sink('out/word2vec/descriptions.txt')
for(i in 1:length(descr)) {
	tmp <- strsplit(descr[[i]], ' ')[[1]]
	tmp <- tmp[!(tmp %in% stop.words)]
	cat(paste(tmp, collapse=' '))
	cat('\n')
}
sink()

