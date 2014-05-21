# slg_pipe

This is a collection of shell scripts written by Eric Anderson to ease the task of running genetic data through a variety of analyses.  It was written around 2010 and was used internally.

Anyone is welcome to use this, though I can't promise that I will be helpful trying to work through any bugs.  We are currently using it on a Mac running Mavericks.  It includes some binaries for Mac, and the code is not available in this repository, so don't plan on using it on a different platform.


## Using it
Here is how you use it


```shell
# First, get it:
git clone https://github.com/eriqande/slg_pipe.git

# then get the external binaries that need to go with it
# For now just download them in a tarball from here:
curl -o slg_pipe_binaries.tar.gz  https://dl.dropboxusercontent.com/u/19274778/slg_pipe_binaries.tar.gz

# extract the tarball
gunzip slg_pipe_binaries.tar.gz 
tar -xvf slg_pipe_binaries.tar 

# now copy the binaries into the directory tree of the 
# repository using rsync
rsync -avh slg_pipe_binaries/* slg_pipe

# now you should be good to go.  Enter the "arena" directory
# and get the directions:
cd slg_pipe/arena/
../script/Do_standard_analyses.sh
```

So, in case you are wondering what slg_pipe format is, it is basically your typical "2-column" genetic format.  Some examples are in the test directory.   The first column are identifiers for individuals and the remaining columns are the genetic data.  There should be two columns for each locus, corresponding to the two alleles.  The first row must be the column headers.  The header for each column of a locus must be identical (i.e. the locus name occurs at the top of each column). **Note that the file must be tab delimited and the first column in the first row must be empty.** The names of the individuals must have a population identifer composed of letters and an individual ID number which must be entirely numeric.  Because of limitations in some of the programs used in the pipeline, you should strive for no more than 5 letters in the population name and no more than 3 numerals in the ID number.  Here is a tiny example file:
```
  Omy1011	Omy1011	Omy77	Omy77	OtsG243	OtsG243
PChor001	164	168	98	102	58	84
PChor002	164	168	98	98	58	58
PChor003	168	172	102	132	58	84
PChor004	164	164	98	102	58	84
PChor005	164	168	102	106	58	84
PChor006	168	172	102	132	84	84
CMont001	180	188	104	108	58	84
CMont002	168	172	92	96	58	84
CMont003	168	172	102	106	58	84
CMont004	156	168	96	106	58	84
CMont005	172	200	102	128	58	58
CMont006	168	176	104	104	58	84
Bould001	164	176	110	110	58	84
Bould002	164	188	0	0	84	84
Bould003	164	168	0	0	58	84
Bould004	188	192	0	0	58	84
Bould005	168	172	96	96	58	84
Bould006	164	168	0	0	58	84
```

Note that missing data are denoted by 0's (zeroes) and alleles are denoted by numbers (it is probably best to denote them by numbers between 100 and 999).

Here is an example analysis on the test data:  
```shell
# issue this command in the "arena" directory
../script/Do_standard_analyses.sh ../test/full_redo_slg_pipe.txt ../test/full_redo_pops.txt ../test/full_redo_loci.txt  FullRedoTest DefaultSettingsStandard.sh
```
The output from that tells you what else you can do.

If you want some summaries, try this once it has finished:
```shell
# do this in the arena directory
../script/SummarizeAll.sh FullRedoTest
```




## Terms 

As a work of the United States Government, this package is in the
public domain within the United States. Additionally, we waive
copyright and related rights in the work worldwide through the CC0 1.0
Universal public domain dedication.

See TERMS.md for more information.

