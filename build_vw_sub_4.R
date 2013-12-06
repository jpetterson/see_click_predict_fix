library(doMC)
registerDoMC()
source('subs.R')

expn    <- 4
out.dir <- sprintf('out/%d', expn)
gt.dir  <- 'out/vw'
files   <- list.files(out.dir, pattern='predictions.*final.*', full.names=T)

get.param.value <- function(key, filename) {
	regexp <- sprintf('.*%s_([^_]*).*', key)
	gsub(regexp, '\\1', filename)
}

get.id.column <- function() {
	load('subs/02.Rd')
	ps$id
}

ps <- foreach(f = files, .combine=cbind) %dopar% {
	p        <- read.table(f)
	names(p) <- get.param.value("model", f)
	p
}

ps        <- expm1(ps)
names(ps) <- sprintf('num_%s', names(ps))
ps$id     <- get.id.column()
ps        <- ps[, c("id", "num_views", "num_votes", "num_comments")]

save.subs(ps, expn)


