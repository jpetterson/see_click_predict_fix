library(doMC)
registerDoMC()

load('out/data2.Rd')
source('data_split.R')

to.vw <- function(d, gt, filename) {
	cat(sprintf('%s\n', filename))
	wordvec.idxs <- which(names(d)=='v1'):ncol(d)
	has.descr    <- ifelse(d$has.descr=='TRUE', 1, 0)
	wordvec      <- foreach(i = 1:nrow(d)) %dopar% { 
		if (is.na(d[i, wordvec.idxs[1]])) {
			''
		} else {
			paste(sprintf('%d:%f', 1:length(wordvec.idxs), d[i, wordvec.idxs]), collapse=' ') 
		}
	}
	tmp          <- sprintf('%f |city %s |main latitude:%f longitude:%f source=%d clean_tag_type=%d has_descr:%d clean_summary=%d |time week:%f wday=%d hour=%d |description %s |wordvec %s', gt, d$city, d$latitude, d$longitude, as.integer(d$source), as.integer(d$clean.tag_type), has.descr, as.integer(d$clean.summary), d$week, d$wday, d$hour, d$description, wordvec)
	writeLines(tmp, filename)
	write.table(gt, file=sub('.vw$', '.gt', filename), col.names=F, row.names=F)
}

system('mkdir -p out/vw')
for (label in c('votes', 'comments', 'views')) {
	colname <- sprintf('l_%s', label)
	to.vw(d.train,      d.train[, colname],      sprintf('out/vw/%s_train.vw', label))
	to.vw(d.valid,      d.valid[, colname],      sprintf('out/vw/%s_valid.vw', label))
	to.vw(d.trainvalid, d.trainvalid[, colname], sprintf('out/vw/%s_trainvalid.vw', label))
	to.vw(d.test,       rep(0, nrow(d.test)),    sprintf('out/vw/%s_test.vw', label))
}

