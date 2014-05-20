
STEPS="
  1. Create the directory ColonyArea with four subdirectories and contents
    a. bin  (where the Colony2 Mac executable goes)
    b. input (where some useful files for making Colony input live)
    c. script (some scripts for running Colony)
    d. Collections (houses one subdirecory for each different collection in the 
                    original data set.  The genotypes from each collection are in
                    the files genotypes.txt in each subdirectory)
  2. Copy the_pops.txt and the_locs.txt to ColonyArea
  3. Prepare the files NumProc.txt and ProcSet_X.txt which tell us how to spread
     the Colony runs across the multiple processors of a single machine.

  Once this is done, this ColonyArea directory can be copied to a fast machine
  like persephone and excecuting the following command from the ColonyArea
  directory should launch all the processes:

            ./script/RunAllColony.sh  RUN Perm? NumProc

  where you change RUN to be the name you want to give to the run and Perm?
  is a 0 if you want the data set to be permuted and a 1 otherwise, and NumProc
  is the number of cores you want to use in the process  So, for
  example you could do:

           ./script/RunAllColony.sh  Simple1   0  4

  Eventually I will write some script to take the output from each such RUN 
  and use it to do some sibyanking.
      
"


if [ $# -ne 4 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile  PopsFile   LocsFile  OutDir 

The GenoFile is the file of genotypes in the slg_pipe format.  PopsFile is the
file of desired populations in slg_pipe format.  LocsFile is the file of
desired loci in slg_pipe format.  OutDir is the name of the directory
into which you want all of this output to go.  It can be a relative
or absolute path.  NumProc is the number of processors you want to 
be able to spread the runs out on.  Persephone has 8 processors and spreading
the work across 6 of those typically works well.

LocsFile can have more than a single column.  If so, the columns can 
hold information about the assumed Dropout rate and Miscall rate at each loci.
If those data are in there, then NullRateColumn and MiscallRateColumn should
give the columns those things are in, and the script will use them.

Actually, I will set that in a config file.

This script does the following:
$STEPS

"

exit 1;

fi;


GF=$1;
PF=$2;
LF=$3;
OUTD=$4;


# set  up the directory structure
mkdir -p $OUTD/{bin,input,script,Collections};


# now make the subdirectories for each Collection and put the original data in there
for i in $(awk 'NF>0 {print $1}' $PF); do
    echo "Making directory $OUTD/Collections/$i"
    mkdir -p $OUTD/Collections/$i;

    echo "Filling genotypes.txt in $OUTD/Collections/$i"
    awk -v pop=$i 'NR>1 && NF>2 {a=$1; gsub(/[0-9]*/,"",a); if(a==pop) print;  } ' $GF  > $OUTD/Collections/$i/genotypes.txt;
    
done



# now copy across the inputs and the scripts that will be needed
cp -r $SLG_PATH/inputs/ForColony/input/* $OUTD/input/
cp -r $SLG_PATH/inputs/ForColony/script/* $OUTD/script/
cp -r $SLG_PATH/inputs/ForColony/bin/* $OUTD/bin/



# and, for good measure we want the pop names and the locus names in the OUTD
cp $PF $OUTD/the_pops.txt
cp $LF $OUTD/the_locs.txt




# now we prepare some more scripts and things to help parallelize
cp $SLG_PATH/inputs/parallel  $OUTD/script/


echo "Done with Prepare_ColonyArea.sh.  Here is what we did:

$STEPS";
