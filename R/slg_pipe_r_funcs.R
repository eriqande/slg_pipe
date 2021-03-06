
library(dplyr)
library(stringr)
library(readr)

#' do sibyanking from a ColonyArea Collection 
#' 
#' This is an R rewrite of a messy function I had written a shell script for
#' @param genos  the file that has all the genotypes in it.  Basically the slg_pipe file.
#' @param CollDir  The "Collections" directory
#' @param Run The name of the set of colony runs
#' @param the_pops  path to the file that has the pops names in it in the order you 
#' want to cycle through things.
#' @param Cutoff  sibships of size < Cutoff all go into the yanked file.  Any sibships
#' with Cutoff or more members have just a single one sampled from them.
#' @param Num  Number of sibyanked data sets to make
#' @param OutDir  path of the output directory where the files should be written.
yank_sibs <- function(genos,
                      CollDir,
                      Run,
                      the_pops,
                      Cutoff = 3,
                      Num,
                      OutDir) {
  
  # get the pops list
  pop_tab <- read_delim(the_pops, delim = "\t", col_names = FALSE)
  pop_vec <- unlist(pop_tab$X1)
  names(pop_vec) <- pop_vec
  
  # now grab the inferred siblings out of all the pops and make a data frame of them
  ugly <- lapply(pop_vec, function(x) {
    read.table(file.path(CollDir, x, Run, "output.BestFSFamily"), skip = 1, header = FALSE, stringsAsFactors = FALSE)
  }) %>%
    bind_rows(.id = "Pop") %>%
    setNames(c("Pop", "sibship_idx", "prob_inc", "prob_exc", "sibs"))
  
  # now, make a tidy data frame of that:
  siblist <- str_split(ugly$sibs, ",")
  tidy <- lapply(1:nrow(ugly), function(r) {
    data.frame(ugly[r,], indiv = siblist[[r]], n_sibs = length(siblist[[r]]), stringsAsFactors = FALSE )
  }) %>% 
    bind_rows() %>%
    select(-sibs) %>%
    tbl_df
  
  # now get the fraction of missing data in each individual and add that to the tidy frame
  gdf <- read.table(genos, sep = "\t", header = TRUE, stringsAsFactors = FALSE) %>% tbl_df()
  names(gdf)[1] <- ""
  
  gmat <- gdf
  rownames(gmat) <- unlist(gmat[,1])
  gmat <- as.matrix(gmat)
  non_miss_fracts <- rowMeans(gmat > 0)
  nmf_df <- data.frame(indiv = names(non_miss_fracts), non_miss_fract = non_miss_fracts, stringsAsFactors = FALSE) %>%
    tbl_df()
  
  # left join that on there
  tidy2 <- left_join(tidy, nmf_df)
  
  # make tidy2$Pop a factor with levels ordered the way we want them to be ordered
  # when we arrange things later
  tidy2$Pop <- factor(tidy2$Pop, levels = pop_vec)
  
  # now we just cycle over the Num data sets and each time we 
  # mutate a new column that says whether we keep the individual or not and then
  # filter that down and pull those indivs out of the slg_pipe file, make sure it
  # is sorted nicely, and then print it out
  yfunc <- function(n, C, nmf) {
    if(n < C) {
      ret <-  rep(TRUE, n)
    } else {
      ret <- rep(FALSE, n)
      ret[sample.int(n, size = 1, prob = nmf)] <- TRUE
    }
    ret
  }
  
  # we also have to get ready to left join genotypes on there
  geno_joiner <- gdf
  names(geno_joiner)[1] <- "indiv"
  
  # now cycle over the number of sibyanked data sets
  lapply(1:Num, function(x) {
    tmp <- tidy2 %>% 
      group_by(Pop, sibship_idx) %>%
      mutate(keep = yfunc(n(), Cutoff, non_miss_fract))
    
    # here we write out the data set
    towrite <- tmp %>%
      filter(keep == TRUE) %>%
      arrange(Pop, indiv) %>%
      ungroup() %>%
      select(indiv) %>%
      left_join(geno_joiner)
    
    names(towrite)[1] <- ""
    names(towrite)[seq(3, ncol(towrite), by = 2)] <- names(towrite)[seq(2, ncol(towrite), by = 2)]  # every two columns with the same locus name
    
    write.table(towrite, 
                file = file.path(OutDir, sprintf("sib-yanked-%03d.txt", x)),
                quote = FALSE,
                row.names = FALSE,
                col.names = TRUE,
                sep = "\t"
    )
    
    # and then for good measure we send tmp back so that we know who got put where.
    tmp
  })
  
}