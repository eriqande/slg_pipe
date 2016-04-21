
STEPS="
  1. Set up an output directory with subddirectories bin, input, script, arena, and data
  2. Convert data files to a structure readable format.  It will save them with 
     their original names + \"_dat0X\", where X is the number in which it was read in
     padded with a zero if need be. 
  3. Prepare some other files with the population indexes, number of indivs. etc. 
  4. Copied over mainparams and extraparams and structure and GNU parallel
  5. Compiled a list of commands to be spread across processors.
  6. Made a script called ExecuteStructureRuns.sh

"


if [ $# -lt 2 ]; then
    echo "Syntax:

    $(basename $0)  Settings   DataFile1  DataFile2 ...  



Settings is the standard slg_pipe settings  file that has options
which impinge upon the operation of this script.

  
The DataFiles are in slg_pipe genotype format.  They must all
have the same number of individuals and should have the same
number of individuals per population.  But otherwise they could
have different individuals in them (as is useful if inputting a
bunch of sibyanked data into it.)



The script then does the following things:

$STEPS
  
"

exit 1;

fi;


if [ -z $SLG_PATH ]; then
    echo "Problem!  You have to export SLG_PATH to point to the slg_pipe directory."
    echo "exiting"
    exit 1;
fi



source $1;
shift;

# set  up the directory structure
mkdir -p ${StructOutDir}/{bin,input,script,data,arena};


# data files for structure. Note that we will have to tell structure that
# missing data is a 0 here and that there is a locus line
cnt=0;
rm -f $StructOutDir/input/InputFileNames.txt
for datfile in "$@"; do
    cnt=$((cnt+1)); 
    awk '
 NF==0 {next} 
 n==0 {for(i=2;i<=NF;i+=2) printf("%s ",$i); printf("\n"); n++; next} 
 n>0 {a=$1; gsub(/[0-9]*/,"",a); if(!(a in pops)) {pops[a]=++p; print p,a > "tempppopidx";} printf("%s    %d    %d    ",$1,p,p); for(i=2;i<=NF;i++) printf(" %d",$i); printf("\n");} 
' $datfile > $StructOutDir/data/$(basename $datfile)_dat`printf "%03d" $cnt`;

    if [ $cnt -eq 1 ]; then
	mv tempppopidx $StructOutDir/data/pop_idxs.txt; # move the list of population numbers int data
	awk 'NR>1 && NF>0 {n++} END {print n}' $StructOutDir/data/$(basename $datfile)_dat`printf "%03d" $cnt` > $StructOutDir/input/N.txt;  # also get the sample size
        awk 'NR==1 {print NF; exit;}'  $StructOutDir/data/$(basename $datfile)_dat`printf "%03d" $cnt` > $StructOutDir/input/L.txt;  # also get the number of loci
    fi;

    # now record the input file names:
    echo $(basename $datfile)_dat`printf "%03d" $cnt` >> $StructOutDir/input/InputFileNames.txt;

    # and give a report:
    echo Done Preparing file  $(basename $datfile)_dat`printf "%03d" $cnt` 
done;



# now we copy over the mainparams and extraparams while changing the NUM_BURNIN and NUMSWEEWPS:
sed "s/xxNUMBURNIN_Val/$StructNumBurnIn/g;
     s/xxNUMREPS_Val/$StructNumSweep/g;  s/xxLOCPRI_Val/$StructUseLocationPrior/g;	"  $StructMainP > $StructOutDir/arena/mainparams
cp  $StructExtraP $StructOutDir/arena/extraparams;


echo; echo
# and copy over structure too:
if [ -z ${StructBinary+x} ]; then 
	echo " "; 
else 
	echo "NOTE: StructBinary is listed as $StructBinary.  Setting of StructBinary is now deprecated.
No problems.  It is just ignored and you get Structure version 2.3.4 by default"
fi
echo; echo



cp $SLG_PATH/inputs/ForStructure/structure2.3.4  $StructOutDir/bin/structure;

# can copy over parallel too:
cp $ParallelScript $StructOutDir/script/parallel;


# now we compile our set of commands:
# first get an integer value from the current date:
SEED_BASE=7$(date | awk '{print $4}' | sed 's/[^1-9]//g;')  # just sort of a hack to take the current time
SEED_INCR=1

# then make the commands, incrementing the seed by some amount, SEED_INCR each time
(echo $KVals; echo $StructReps; cat $StructOutDir/input/InputFileNames.txt)  | \
awk -v N=$(cat $StructOutDir/input/N.txt) -v L=$(cat  $StructOutDir/input/L.txt)  -v seed_incr=$SEED_INCR -v seed_base=$SEED_BASE '
 NR==1 {numK=NF; for(i=1;i<=NF;i++) Ks[i]=$i; next}
 NR==2 {if(NF==1) {for(i=1;i<=NF;i++) Reps[i]=$1;} else {for(i=1;i<=NF;i++) Reps[i]=$i;} next;}
 {
  dat=$1;
  for(i=1;i<=numK;i++) {
   K=Ks[i];
   for(r=1;r<=Reps[i];r++) {
    
    printf("echo \"Starting Rep  %d  of K= %d for data set %s at $(date)\"; ../bin/structure  -K %d -i ../data/%s  -N %d -L %d -D %d -o StructOuput_%s_k%03d_Rep%03d.txt > StdoutStruct_%s_k%03d_Rep%03d.txt;  echo \"Done with Rep  %d  with K= %d for data set %s at $(date)\"\n", r,K,dat,K,dat,N,L,seed_base+(++tots*seed_incr),dat,K,r,dat,K,r,r,K,dat);

   }
  }
 } 
'  >  $StructOutDir/input/Commands.txt 




# now, make a short script that uses parallel:
echo "
if [ \$# -ne 1 ]; then
echo Syntax:
echo \$(basename \$0) NumProc
echo \"
NumProc is the number of processors to spread this job over.
You should set it to be the number of cores on your machine 
or one less than that, etc.

\"
exit 1;
fi;

cat ../input/Commands.txt  | ../script/parallel -P\$1

" >  $StructOutDir/script/ExecuteStructureRuns.sh
chmod u+x $StructOutDir/script/ExecuteStructureRuns.sh;


echo "Done with Prepare_StructureArea.sh.  Here is what we did:

$STEPS";

echo "
To run you data, go to the \"arena\" directory inside $StructOutDir
and execute the command:

nohup ../script/ExecuteStructureRuns.sh  NumProc  > BIG_LOG.txt  2>&1 &

This will put jobs on NumProc cores on your machine.

" 



# and, at the end we copy over all the clump and distruct stuff
# first, copy over the clump_and_distruct directory
cp -r $ClumpAndDistruct $StructOutDir/

# then put the pop_names file there by picking out the desired column
awk -F"\t" -v col=$DistructNamesColumn '{print ++n, $col}' $StructThePops > $StructOutDir/$(basename $ClumpAndDistruct)/pop_names.txt;


