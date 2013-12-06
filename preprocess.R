# load raw data 
# -------------

source('config.R')

d            <- read.csv(train.path)
d$l_votes    <- log1p(d$num_votes)
d$l_comments <- log1p(d$num_comments)
d$l_views    <- log1p(d$num_views)
d$time       <- as.POSIXct(d$created_time)
d$month      <- substr(d$created_time, 1, 7)
d$has.descr  <- as.factor(d$description!='')

d.test           <- read.csv(test.path)
d.test$time      <- as.POSIXct(d.test$created_time)
d.test$month     <- substr(d.test$created_time, 1, 7)
d.test$has.descr <- as.factor(d.test$description!='')

# clean up summary and tag_type, add city
# ---------------------------------------

clean.up.summaries <- function(s) {
	# fix some of the them
	regexp2val <- list(
		'trash'           = 'trash',
		'bulk pick'       = 'trash',
		'graffiti'        = 'graffiti',
		'street light'    = 'street_light',
		'rodent'          = 'rodents',
		'brush'           = 'brush',
		'trimming'        = 'trimming',
		'pothole'         = 'pothole',
		'bulk'            = 'bulk',
		'overgrown lot'   = 'overgrown_lot',
		'illegal dumping' = 'illegal_dumping'
	)

	fsummary <- as.character(s)
	for(regexp in names(regexp2val)) {
		val <- unlist(regexp2val[regexp])
		fsummary[grep(regexp, fsummary, ignore.case=T)] <- val
	}

	# put the rest in a single category
	tmp  <- data.frame(table(fsummary))
	tmp  <- tmp[tmp$Freq<100,]
	idxs <- which(fsummary %in% tmp$fsummary)
	fsummary[idxs] <- 'summary_removed'
	as.factor(fsummary)
}

clean.up.tag_type <- function(s) {
	# merge duplicates
	tags <- as.character(s)
	tags[tags=='abandoned_vehicle'] <- 'abandoned_vehicles'

	# put infrequent ones in a single category
	tmp  <- data.frame(table(tags))
	tmp  <- tmp[tmp$Freq<100,]
	idxs <- which(tags %in% tmp$tags)
	tags[idxs] <- 'other'
	as.factor(tags)
}

get.city <- function(d) {
	city                                         <- ''
	city[d$longitude < -120]                     <- 'oakland'
	city[(d$longitude > -120) & (d$latitude<39)] <- 'richmond'
	city[(d$latitude>40) & (d$longitude < -80)]  <- 'chicago'
	city[(d$latitude>40) & (d$longitude > -80)]  <- 'new_haven'
	as.factor(city)
}

n1 <- nrow(d)
n2 <- nrow(d.test)

txt                  <- clean.up.summaries(c(as.character(d$summary), as.character(d.test$summary)))
d$clean.summary      <- txt[1:n1]
d.test$clean.summary <- txt[(n1+1):(n1+n2)]


txt                   <- clean.up.tag_type(c(as.character(d$tag_type), as.character(d.test$tag_type)))
d$clean.tag_type      <- txt[1:n1]
d.test$clean.tag_type <- txt[(n1+1):(n1+n2)]

d$city      <- get.city(d)
d.test$city <- get.city(d.test)


# add time of day and day of week
# -------------------------------

first.time  <- min(d$time)
d$week      <- as.numeric(difftime(d$time, first.time, units='weeks'))
d.test$week <- as.numeric(difftime(d.test$time, first.time, units='weeks'))

d$wday      <- as.POSIXlt(d$time)$wday
d.test$wday <- as.POSIXlt(d.test$time)$wday

d$hour      <- as.POSIXlt(d$time)$hour
d.test$hour <- as.POSIXlt(d.test$time)$hour


save(d, d.test, file='out/data1.Rd')



# counts of words and characters in summary and description
# ---------------------------------------------------------

d$summary.nchar      <- nchar(as.character(d$summary))
d$description.nchar  <- nchar(as.character(d$description))
d$summary.nword      <- sapply(strsplit(as.character(d$summary), ' '), length)
d$description.nword  <- sapply(strsplit(as.character(d$description), ' '), length)

d.test$summary.nchar      <- nchar(as.character(d.test$summary))
d.test$description.nchar  <- nchar(as.character(d.test$description))
d.test$summary.nword      <- sapply(strsplit(as.character(d.test$summary), ' '), length)
d.test$description.nword  <- sapply(strsplit(as.character(d.test$description), ' '), length)

save(d, d.test, file='out/data1b.Rd')


# counts of UPCASE and "!" characters in summary and description
# --------------------------------------------------------------

count.upcases.and.exclamations <- function(st) {
	r <- matrix(nrow=length(st), ncol=2, data=0)
	for(i in 1:length(st)) {
		m      <- unlist(gregexpr('[A-Z]{2,}', st[i]))
		r[i,1] <- if (m[1]==-1) 0 else length(m)
		m      <- unlist(gregexpr('!', st[i]))
		r[i,2] <- if (m[1]==-1) 0 else length(m)
	}
	colnames(r) <- c('ncaps', 'nexcl')
	r
}

tmp1a <- count.upcases.and.exclamations(as.character(d$summary))
tmp1b <- count.upcases.and.exclamations(as.character(d$description))
tmp2a <- count.upcases.and.exclamations(as.character(d.test$summary))
tmp2b <- count.upcases.and.exclamations(as.character(d.test$description))

colnames(tmp1a) <- sprintf('summary.%s', colnames(tmp1a))
colnames(tmp2a) <- sprintf('summary.%s', colnames(tmp2a))

colnames(tmp1b) <- sprintf('description.%s', colnames(tmp1b))
colnames(tmp2b) <- sprintf('description.%s', colnames(tmp2b))

d      <- cbind(cbind(d, tmp1a), tmp1b)
d.test <- cbind(cbind(d.test, tmp2a), tmp2b)

save(d, d.test, file='out/data1c.Rd')


# convert NAs in extra category (for randomforest and other algorithms that do not support NAs)
# ---------------------------------------------------------------------------------------------

for(col.name in c('source', 'tag_type', 'clean.tag_type')) {
	n1 <- nrow(d)
	n2 <- nrow(d.test)
	v  <- c(as.character(d[, col.name]), as.character(d.test[, col.name]))
	v[is.na(v)]        <- 'NA'
	v                  <- as.factor(v)
	d[, col.name]      <- v[1:n1]
	d.test[, col.name] <- v[(n1+1):(n1+n2)]
}

save(d, d.test, file='out/data1d.Rd')




# random forest cannot deal with more then 32 levels in a categorical var
# -----------------------------------------------------------------------

tmp <- c(as.character(d$clean.summary), as.character(d.test$clean.summary))
ns  <- sort(table(tmp))
tmp[tmp %in% names(ns)[ns<200]] <- 'Other'
tmp <- as.factor(tmp)
n1  <- nrow(d)
n2  <- nrow(d.test)
d$clean.summary2      <- tmp[1:n1]
d.test$clean.summary2 <- tmp[(n1+1):(n1+n2)]
rm(tmp, ns, n1, n2)

save(d, d.test, file='out/data1e.Rd')

