# slg_pipe

This is a collection of shell scripts written by Eric Anderson to ease the task of running genetic data through a variety of analyses.  It was written around 2010 and was used internally.

Anyone is welcome to use this, though I can't promise that I will be helpful trying to work through any bugs.  We are currently using it on Macs running Yosemite or El Capitan.  It includes some binaries for Mac, and the code is not available in this repository, so don't plan on using it on a different platform.

For a tutorial on how to use it, see 
[Devon Pearse's Tutorial](https://github.com/eriqande/slg_pipe/blob/master/devon_pipe_primer.md)


## Using it

First you have to get it and its dependencies.

Most of the dependencies are obtained in the steps below, but you do need to have
Ghostscript on your Mac, and you need to have LaTeX if you want to make multipage
documents with a lot of distruct plots.  So, first install MacTex from
https://tug.org/mactex/mactex-download.html

You also need to have an installation of R on your system, and `Rscript` must be
on your PATH.

We used to store many of the binaries in an archive on Dropbox, but I have
now just put them in the repo. This simplifies installation.

```sh
# Now, get slg_pipe:
git clone https://github.com/eriqande/slg_pipe.git


# now you should be good to go.  Enter the "arena" directory
# and get the directions:
cd slg_pipe/arena/
../script/Do_standard_analyses.sh
```

Then, in order to do a test run of a small data set to make sure that everything is functioning correctly,
you can do this:
```sh
# 1. Run the standard analysis script from within the "arena" directory
# This creates the output directory FIRST_TEST
../script/Do_standard_analyses.sh ../test/test1_genotypes.txt ../test/test1_all_pops.txt ../test/test1_all_loci.txt FIRST_TEST ../settings/QuickRunsTestSettings.sh 

# 2. change into the output directory
cd FIRST_TEST

# 3. Do the very short structure run across 5 processors
cd StructureArea/arena
nohup ../script/ExecuteStructureRuns.sh  5  > BIG_LOG.txt  2>&1 &
```
At this juncture you have to let those structure runs finish.  That should take only
a couple of minutes or less (it takes a second or two on my new M1 Mac).
When they are done you should see see 10 files with names
like `StructOuput_genos_slg_pipe.txt_dat001_k002_Rep001.txt_f`.  Then you can proceed
with the following:
```sh
# 4. clump the output, create distruct plots of it, and latex a file of results
# Here we tell it to make each distruct plot 6 inches wide
cd ../clump_and_distruct
./script/ClumpAndDistructAll.sh 6

# 5. Then we put all the distruct plots together in a LaTeX document
./script/LaTeXify.sh -b ./final_pdf "2 3 4 5" > first_test_struct.tex
pdflatex first_test_struct.tex 

# 6. open that file with a PDF viewer.  It's gonna be ugly because the runs were super short
open first_test_struct.pdf
```

Then, if you want to run Colony:
```sh
# 7. If you are so inclined run the samples from these 7 populations in the
#    test data set through Colony to identify siblings within each population sample which
#    is assumed to consist of a single cohort.  Here we spread the effort across 7 
#    processors (if you machine has at least that many) and we make males 
#    monogamous and females polygamous, and we use the sibship-size-prior (-s)
#    of medium strength (2) with average paternal sibship size of 2.1 and average
#    maternal sibship size of 3.2.  All the output goes into a directory named
#    FirstColonyRun inside each populations subdirectory in the directory called
#    "Collections" which is inside the ColonyArea.  This will take a couple of minutes
#    if you have a lot of processors.  More if you don't.

#    Note, this is using an older version of Colony which has "expired". To be able
#    to run it, we have to set the date in our shell back to a time in the 2018's.  

cd ../../ColonyArea  # change directories to the ColonyArea inside FIRST_TEST

sudo date 0613182785  # change the date (requires admin privileges) or you
                      # could change the date
                      # to June 13, 2018
                      
./script/RunAllColony.sh -o " -P \"1 0\" -s \"2 2.1 3.2 \" "  FirstColonyRun  0 7 

# 8. At the end of that.  Look at all the output files that you have
ls Collections/*/FirstColonyRun

```


Then, if you want to do Colony, but permute the genetic data around, you can run the
following block.  Miraculously, `sgm_perm` runs on 64 bit...

```sh
# 8.5 Note that if you had wanted to do another set of Colony runs just like those
#     ones you just did, but have the data permuted amongst all the individuals
#     in each data set (using Eric's sgm_perm program) you could do that like this:
#     (the key is the "1" near the end of the line --- that is what tell the script
#     to permute things)
./script/RunAllColony.sh -o " -P \"1 0\" -s \"2 2.1 3.2 \" "  FirstColonyRun_Permed  1 7 
```

Finally you can make summaries of a lot of things:

```sh
# 9. If you want to summarize the Genepop HW and LD tests that got done in 
#    Step #1, you can do the following.  It tells you which summary files
#    were produced and where to find them.
cd ../../  # change directories back up to the "arena"
../script/SummarizeAll.sh FIRST_TEST 
```

## slg_pipe format

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


## Terms 

As a work of the United States Government, this package is in the
public domain within the United States. Additionally, we waive
copyright and related rights in the work worldwide through the CC0 1.0
Universal public domain dedication.

See TERMS.md for more information.

