# Pipeline Wiki

This Wiki page describes using the MEGA Standard Lab Genetics Pipeline (slg_pipe), 
used by MEGA to create and process infiles and run several common population 
genetic analyses. The output also feeds into additional analytical tools, many 
run in R, which can be found elsewhere on the lab's internal Wiki. The core of the
pipeline is a series of command-line based Unix scripts developed by Eric Anderson.
The first version was completed in August 2011.
 --- //[[devon.pearse@noaa.gov|Devon Pearse]] 2014/02/28 05:39//

## Useful Unix Commands

* `scp`; secure copy
* `ls`; lists contents of current directory
* `cd`; change directory. ".." goes one directory up.
* `ssh pipe@persephone`
* `rm`; remove. `rm -r` to really remove shit— be careful with this!!
* `kill %1`; kills running program.
* `top`; shows list of processess running.
* `nohup`; used at the beginning of a command line, keeps persephone from 
getting hung up if/when it looses contact with the initiating computer.


## SETUP

* The pipeline is set up in an account called ‘pipe’ on the computer Persephone, which has 8 cores and will always
have the most updated version of slg_pipe on it. Of course, if you set the slg_pipe up on your own computer
then you will just be running things there.  But, this is written as if being run on persephone.
* Next use the Finder to network to persephone (or use apple-k); login to 'pipe'.

On persephone, all the pipeline stuff is in a directory called `Documents/Users/slg_pipe/`

Make a directory for your infiles, e.g. 
```sh 
mkdir Documents/slg_pipe/DevonStuff/
```
This is where you will put input files, etc. To run the pipeline, you will need four files.
Start with your INPUT FILE. The format is "Toolkit", tab-delimited text (INFILE.txt). Make sure all
locus names are consistent, and they must also be letter based---the pipeline will strip off all
numbers to create the population names. Place infile in folder `pipe/Documents/slg_pipe/YOURStuff/`

Now, as a test run some preliminaries; this will test your infile and generate a list of popualtions and a list of loci.
First, every time you start a new pipeline session, you need to set up the environment by running this
script from within the `arena` directory:
```sh
source ../script/declare_location_and_paths.sh;
```
This tells the .sh scripts where to find various necessary components.

Now you can begin by running these two scripts while currently in the `arena` directory:
```sh 
	../script/pops_list_from_sgl_pipe.sh ../YOURstuff/INFILE.txt > PROJECT_pops.txt 

	../script/locus_list_from_sgl_pipe.sh ../YOURstuff/INFILE.txt > PROJECT_locs.txt
```

These files are your POPULATIONS FILE and LOCI FILE, and can later be edited to, for example,
drop a particular locus from the analysis.

Finally, you need a SETTINGS FILE. Start with a copy of the default file (DefaultSettingsStandard.sh). 
You can do this from the command line with: 
```sh
cp DefaultSettingsStandard.sh NAMEOFCOPY.sh
```
Or, just make a copy of the file via the finder. Either way, you will edit this file with the settings for your run. 
The main options are:

```sh
DO_GSI_SIM_STUFF=1;         # 1 means do the MissingDataTable and the GeneClass AssMat
DO_PHYLIP_STUFF=1;          # 1 means build CSE-NJ tree and consensus tree and transfer bootstrap values back to the distance tree
DO_GENEPOP=1                # must be 1 to do any genepop analyses at all
DO_GENEPOP_HWE=0;           # 1 means do Guo and Thompson MCMC Fisher Exact test for HWE and 0 means do not do it
DO_GENEPOP_LD=0;            # 1 means test for LD between all pairs of loci and 0 means do not do it
PREPARE_COLONY_AREA=0;      # 1 means make the ColonyArea with everything needed to run Colony on each separate population
PREPARE_FSTAT_DIR=0;        # make the fstat directory which gives you an input file for fstat
PREPARE_GENETIX_DIR=1;      # make the genetix directory with an fstat file to import into genetix
PREPARE_STRUCTURE_AREA=1;   # make a directory for Structure stuff.
DO_ISOL_BY_DIST=0;
```
It is best to not change the directory name options, etc...

## Running the Pipeline
To RUN the pipeline in the Terminal:  
```sh
../script/Do_standard_analyses.sh ../YOURSTUFF/INFILE.txt ../YOURSTUFF/PROJECT_pops.txt ../PROJECT_locs_.txt  PROJECT_outputfolder DefaultSettingsStandard.sh
```
A run start might look like this:
```sh
../script/Do_standard_analyses.sh  ../DevonStuff/CV_2011allTK.txt ../DevonStuff/CVandH_pops.txt ../DevonStuff/CVandH_locs.txt DevRun1OnPersephone DevonFirstRun.sh  > DevonFirstRunOutput.LOG 2>&1 &
```
The last part (` > DevFirstRunOutput.LOG 2>&1 &`) is optional. The script will create an output folder with
whatever name you provide and put it inside the arena folder. All results are contained within this folder. 

After this, you can run additional scrips as described in the buffer to run COLONY, FSTAT, and 
GENETIX, and STRUCTURE (and DISTRUCT and CLUMPP too). E.g.;
```sh
nohup ../script/ExecuteStructureRuns.sh NumProc > BIG_LOG_CVonly.txt 2>&1 &
```
**Change "NumProc" to 1 or 2, 7, etc. depending on how many processors you want to use.**
This will run STRUCTURE-- it takes a lot of computational time if you are doing multiple runs. Great to set up overnight.
After that you need to run one more script to run CLUMPP and DISTRUCT on your STRUCTURE output. This will produce
nice usable figure files in PDF and EPS. Navigate into the clump_and_distruct folder inside the StructureArea
folder and then run: 
```sh
./script/ClumpAndDistructAll.sh NumberOfIncheswhere "NumberOfInches is 6 or 7 or however wide you want your figures to be.
```

## Quick_Guide

- Connect to Persephone via regular Finder network. In slg_pipe directory, create a YourStuff folder.
Put your Toolkit formatted infile in this folder.
- Navigate into the "arena" folder: `cd ~/Documents/slg_pipe/arena`	
- Set up the Pipeline by running this script from the `arena`
```sh 
source ../script/declare_location_and_paths.sh;
```
- Run the following two scripts from the `arena`:
```sh
../script/pops_list_from_sgl_pipe.sh ../YOURSTUFF/INFILE.txt > PROJECT_pops.txt
../script/locus_list_from_sgl_pipe.sh ../YOURSTUFF/INFILE.txt > PROJECT_locs.txt
```
(here and in all scripts, capital letters should be customized to your project).
- In the Finder window, you will now have the PROJECT_pops.txt and PROJECT_locs.txt files in the arena. 
You can open them to check that they are correct, and edit them to remove particular loci or populations,
or change the order that they will appear in the outfiles. ( Put PROJECT_pops.txt and PROJECT_locs.txt in YOURSTUFF )
- Make a new settings file. Start with a copy of the default file "DefaultSettingsStandard.sh" in the `arena`, 
and re-name it "YOURPROJECTsettings.sh". Edit as needed.
- Start your pipeline run from the `arena`
```sh
../script/Do_standard_analyses.sh  ../YOURSTUFF/INFILE.txt ../YOURSTUFF/PROJECT_pops.txt ../YOURSTUFF/PROJECT_locs.txt PROJECTOUTFOLDER YOURPROJECTsettings.sh  > YOURPROJECToutput.log 2>&1 &
```

## STRUCTURE

Run STRUCTURE (where "NUMPROC" is how many processors you want to use): 
```sh 
# execute command in: slg_pipe/arena/PROJECTOUTFOLDER/StructureArea/arena 
nohup ../script/ExecuteStructureRuns.sh NumProc > BIG_LOG_CVonly.txt 2>&1 &
```

Run CLUMP and DISTRUCT (where INCHES is however wide you want your figures to be (e.g. 6 ):  
```sh
# execute command in: slg_pipe/arena/PROJECTOUTFOLDER/StructureArea/clump_and_distruct
./script/ClumpAndDistructAll.sh INCHES
```
where INCHES is however wide you want your figures to be (e.g. 6 ).
At this point you end up with a bunch of distruct pdf files (one for each run for each k) located in a
folder call "final_pdf". If you want to stack all the distruct plots for a single k on top of one
another you can use the script LaTeXify.sh, which spits a file that you can visualize using LaTeX:

Run the script (where the "string of k-values" is the specific k you want to stack (e.g. "2 3 4 5")): 
```sh
# execute command in: slg_pipe/arena/YOURPROJECTOUTFOLDER/StructureArea/clump_and_distruct
./script/LaTeXify.sh ./final_pdf/ "string of k-values" > YOURPROJECT.tex
```

## COLONY
COLONY instructions - added by A. Clemento 3/11/2013 (also made the code sections a little more clear)

To run COLONY:
The COLONY area set-up does the following: Creates the directory ColonyArea with four subdirectories and contents
- bin  (where the Colony2 Mac executable goes)
- input (where some useful files for making Colony input live)
- script (some scripts for running Colony)
- Collections (houses one subdirecory for each different collection in the original data set.  The genotypes from each collection are in                     the files genotypes.txt in each subdirectory)

Make sure that `the_pops.txt` and `the_locs.txt` were copied into ColonyArea. Navigate into your
ColonyArea folder and copy the Colony2 executable into the bin folder
(where YOURPATH is the path on pipe to your ColonyArea folder):
```sh
cp ~/Documents/slg_pipe/colony/Colony2 YOURPATH/ColonyArea/bin/
```

Run COLONY from within the ColonyArea folder (where RUN is the name you want to give to the run and Perm? is a 
0 if you want the data set to be permuted and a 1 otherwise, and NumProc is the number of cores you want to use in the process):
```
sh ./script/RunAllColony.sh  RUN Perm? NumProc
```
  
So, for example you could do:
```sh
./script/RunAllColony.sh  Simple1   0  4
```

Note: `nohup` is not necessary as it is built into the `RunAllColony.sh` script (but it can't hurt!)

