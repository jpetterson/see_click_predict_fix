save.subs <- function(ps, id) {
	save(ps, file=sprintf('subs/%02d.Rd', id))
	write.csv(ps, file=sprintf('subs/%02d.csv', id), row.names=F, quote=F)

	# build submission file for each model individually
	psc              <- ps
	psc$num_votes    <- 0
	psc$num_comments <- 0
	write.csv(psc, file=sprintf('subs/%02d_views.csv', id), row.names=F, quote=F)
	
	psc              <- ps
	psc$num_votes    <- 0
	psc$num_views    <- 0
	write.csv(psc, file=sprintf('subs/%02d_comments.csv', id), row.names=F, quote=F)
	
	psc              <- ps
	psc$num_comments <- 0
	psc$num_views    <- 0
	write.csv(psc, file=sprintf('subs/%02d_votes.csv', id), row.names=F, quote=F)
}


