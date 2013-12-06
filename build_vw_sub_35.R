library(doMC)
registerDoMC()
source('subs.R')

get.param.value <- function(key, filename) {
	regexp <- sprintf('.*%s_([^_]*).*', key)
	gsub(regexp, '\\1', filename)
}

get.id.column <- function() {
	load('subs/02.Rd')
	ps$id
}


expn    <- 35
out.dir <- sprintf('out/%d', expn)
gt.dir  <- 'out/vw'


load('out/data2.Rd')
id.and.city <- d.test[, c('id', 'city')]
rm(d, d.test)

cities   <- as.character(unique(id.and.city$city))
for(i in 1:length(cities)) {
	city     <- cities[i]
	files    <- list.files(out.dir, pattern=sprintf('predictions.city_%s.*final.*', city), full.names=T)
	p        <- read.table(files[1])
	p        <- expm1(p)
	names(p) <- sprintf('num_%s', get.param.value('model', files[1]))

	# fill other cities' predictions with zeroes
	load('subs/02.Rd')
	stopifnot(all(id.and.city$id == ps$id))

	ps[,-1] <- 0
	idxs    <- which(id.and.city$city==city)
	co      <- which(names(ps)==names(p))
	ps[idxs, co] <- p

	sub.n <- expn+i-1
	cat(sprintf('%d: %s\n', sub.n, city))
	save.subs(ps, sub.n)
}

