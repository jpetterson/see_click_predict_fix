# load raw data and save in R format
# ----------------------------------

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
	fsummary <- as.character(s)
	fsummary[grep('trash', fsummary, ignore.case=T)]           <- 'trash'
	fsummary[grep('bulk pick', fsummary, ignore.case=T)]       <- 'trash'
	fsummary[grep('graffiti', fsummary, ignore.case=T)]        <- 'graffiti'
	fsummary[grep('street light', fsummary, ignore.case=T)]    <- 'street_light'
	fsummary[grep('rodent', fsummary, ignore.case=T)]          <- 'rodents'
	fsummary[grep('brush', fsummary, ignore.case=T)]           <- 'brush'
	fsummary[grep('trimming', fsummary, ignore.case=T)]        <- 'trimming'
	fsummary[grep('pothole', fsummary, ignore.case=T)]         <- 'pothole'
	fsummary[grep('bulk', fsummary, ignore.case=T)]            <- 'bulk'
	fsummary[grep('overgrown lot', fsummary, ignore.case=T)]   <- 'overgrown lot'
	fsummary[grep('illegal dumping', fsummary, ignore.case=T)] <- 'illegal dumping'

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


d$clean.summary      <- clean.up.summaries(d$summary)
d.test$clean.summary <- clean.up.summaries(d.test$summary)

tmp <- setdiff(levels(d.test$clean.summary), levels(d.train$clean.summary))
d.test$clean.summary <- as.character(d.test$clean.summary)
d.test$clean.summary[d.test$clean.summary %in% tmp] <- 'summary_removed'
d.test$clean.summary <- as.factor(d.test$clean.summary)

d$clean.tag_type      <- clean.up.tag_type(d$tag_type)
d.test$clean.tag_type <- clean.up.tag_type(d.test$tag_type)

d$city      <- get.city(d)
d.test$city <- get.city(d.test)

first.time  <- min(d$time)
d$week      <- as.integer(as.integer(d$time-first.time)/86400.0/7.0)
d.test$week <- as.integer(as.integer(d.test$time-first.time)/86400.0/7.0) # <- this is wrong!

d.train      <- d[d$month>='2012-10' & d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- d[d$month>='2012-10' & d$month<='2013-04',]
save(d, d.train, d.valid, d.trainvalid, d.test, file='out/data0.Rd')

