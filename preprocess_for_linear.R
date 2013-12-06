library(caret)
library(doMC)
registerDoMC()
source('common.R')

load('out/data2.Rd') # using 2 to get clean up descriptions

# combine all data
n1   <- nrow(d)
n2   <- nrow(d.test)
cols <- c('month', 'latitude', 'longitude', 'description', 'source', 'has.descr', 'clean.summary', 'clean.tag_type', 'city', 'wday', 'hour')
d1   <- rbind(d[, cols], d.test[, cols])
gt   <- d[, labels]



# treat NAs as additional category
na.as.category <- function(v) {
	v           <- as.character(v)
	v[is.na(v)] <- 'NA'
	as.factor(v)
}
d1$source         <- na.as.category(d1$source)
d1$clean.summary  <- na.as.category(d1$clean.summary)
d1$clean.tag_type <- na.as.category(d1$clean.tag_type)

# this is binary, so one integer is enough
d1$has.descr <- ifelse(d1$has.descr=='TRUE', 1, 0)

# these should be treated as categoricals
d1$city <- as.factor(d1$city)
d1$wday <- as.factor(d1$wday)
d1$hour <- as.factor(d1$hour)

# hot encoding for categories
m  <- dummyVars(~ source + clean.summary + clean.tag_type + city + wday + hour, data=d1)
p  <- predict(m, d1)
d2 <- cbind(d1[, c('month', 'latitude', 'longitude', 'has.descr')], p)

# save first version (no description)
d      <- cbind(gt, d2[1:n1,])
d.test <- d2[(n1+1):(n1+n2),]
save(d, d.test, file='out/data3.Rd')

desc <- d1$description


# description:
# ------------


# list of words that occur at least 100 times
tmp <- table(unlist(strsplit(desc, ' ')))
tmp <- as.data.frame(tmp, stringsAsFactors=F)
tmp <- tmp[tmp$Freq>=100,]
names(tmp)[1] <- 'word'

# remove numbers
idxs <- grep('[0-9]', tmp$word)
tmp  <- tmp[-idxs,]

# dictionary: map each word to an integer
dict        <- 1:nrow(tmp)
names(dict) <- tmp$word

# document term matrix
m <- matrix(nrow=length(desc), ncol=length(dict), data=0)
for (i in 1:length(desc)) {
	cat(sprintf('%d/%d\n', i, length(desc)))
	tmp <- table(dict[strsplit(desc[i], ' ')[[1]]])
	if (length(tmp>0)) { m[i, as.integer(names(tmp))] <- tmp }
}
colnames(m) <- names(dict)

# term frequency
tf <- log1p(m)

# inverse document frequency
idf <- log(nrow(m) / colSums(m>0))

# TF-IDF
tfidf           <- tf * matrix(data=idf, nrow=nrow(tf), ncol=ncol(tf), byrow=T)
colnames(tfidf) <- sprintf('tfidf.%s', colnames(tfidf))
save(m, tf, idf, tfidf, file='out/data4_tfidf.Rd')

load(file='out/data3.Rd')
d      <- cbind(d, tfidf[1:n1,])
d.test <- cbind(d.test, tfidf[(n1+1):(n1+n2),])
save(d, d.test, file='out/data4.Rd')


