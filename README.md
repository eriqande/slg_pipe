# slg_pipe

This is a collection of shell scripts written by Eric Anderson to ease the task of running genetic data through a variety of analyses.  It was written around 2010 and was used internally.

Anyone is welcome to use this, though I can't promise that I will be helpful trying to work through any bugs.  We are currently using it on a Mac running Mavericks.  It includes some binaries for Mac, and the code is not available in this repository, so don't plan on using it on a different platform.


## Using it
Here is how you use it


```
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

So, in case you are wondering what slg_pipe format is, it is basically your typical "2-column" genetic format.  Some examples are in the test directory.

Here is an example analysis from whence you can figure out what the file formats need to be, etc.
```
# issue this command in the "arena" directory
../script/Do_standard_analyses.sh ../test/full_redo_slg_pipe.txt ../test/full_redo_pops.txt ../test/full_redo_loci.txt  FullRedoTest DefaultSettingsStandard.sh
```
The output from that tells you what else you can do.

If you want some summaries, try this once it has finished:
```
# do this in the arena directory
../script/SummarizeAll.sh FullRedoTest
```




## Terms 

As a work of the United States Government, this package is in the
public domain within the United States. Additionally, we waive
copyright and related rights in the work worldwide through the CC0 1.0
Universal public domain dedication.

See TERMS.md for more information.

