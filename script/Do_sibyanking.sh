if [ $# -ne 4 ]; then 
    echo "Syntax 
    $(basename $0)  Dir  Run  Cutoff  Num

This script is intended to be run in the slg_pipe 
\"arena\" directory only.   And, of course,
you need to have already run Colony on all the 
Collections in the ColonyArea.

Dir is the directory in arena where all the 
slg_pipe output that you want to sibyank from
lives.

Run is the name of the Colony Run to draw the
results from.

Cutoff is the size of full sibships to ignore.  That
is to say, a sibship of size Cutoff or larger will get
a single sib yanked from it, and if of  size less than Cutoff
then all members will get yanked into the resulting 
data set.  A typical Cutoff is 3.

Num is the number of sibyanked data sets to create.
They  will be created in slg_pipe format
in an output directory called SibYank_${Dir}_${Run}
and the locus and pops file will go in there too, in the
ColonyArea directory.

It also creates the file ${RUN}_all_full_sibships.txt
in the  ColonyArea, and from this it produces the 
file ${RUN}_inferred_sib_sizes_summary.txt.

"
exit 1;
fi


DIR=$1;
RUN=$2;
CUT=$3;
NUM=$4;





# first declare location and paths
source ../script/declare_location_and_paths.sh || exit 1;


ARENA=$(pwd);


# then go to the ColonyArea directory
cd $DIR/ColonyArea || exit 1;

# first make a single file with all the sibships.
# note that first column in this file is index and second is the sibship 
# probability and th remaining columns are the members of
# the inferred sibship.
rm -f  ${RUN}_all_full_sibships.txt;
for i in $(awk '{print $1}' the_pops.txt); do 
    awk 'NR>1 {for(i=1;i<=NF;i++) printf("%s ",$i); printf("\n");}
         ' Collections/$i/$RUN/${i}_${RUN}.BestFSFamily >> ${RUN}_all_full_sibships.txt || exit 1;  
done;



# then we create a file with missing alleles for each individual
awk 'NR>1 {n=0; for(i=2;i<=NF;i++) n+=($i!=0); print $1,n}' ../genos_slg_pipe.txt > NumTypedGeneCopies.txt;


# create an output directory
OUTD=SibYank_${DIR}_${RUN}
mkdir $OUTD;


# then we repeatedly do the sib_yank_em.awk  script
# first get more than the number of random numbers we will need
NUM_RAND=$(wc ../genos_slg_pipe.txt | awk '{print $1+100}')

for((R=1;R<=NUM;R++)); do
( head -n 1 ../genos_slg_pipe.txt;
(
    cl_rand -r $NUM_RAND  0 1; 
    cat NumTypedGeneCopies.txt; 
    echo "xxxxxxxxxxxxxxxxxxxx"; 
    cat ${RUN}_all_full_sibships.txt; 
    echo "xxxxxxxxxxxxxxxxxxxxxxxxx"; 
    cat ../genos_slg_pipe.txt) | \
awk -v Cutoff=$CUT -f $SLG_PATH/script/yank_em_sibs.awk
) > $OUTD/sib_yanked_`printf "%03d" $R`.txt
done;

# then, at the end copy the_pops.txt and the_loci.txt to OUTD
cp ../the_pops.txt ../the_locs.txt $OUTD/


# now, this is a super ugly series of commands to summarize the sizes of the sibships.
# so be it.
(awk '{numsibs=NF-2; a=$3; gsub(/[0-9]*/,"",a); printf("%s\t%.4d\n", a,numsibs);}' ${RUN}_all_full_sibships.txt | sort -r | \
 awk 'NR==1 {printf("%s\t%d",$1,$2); pop=$1; next} {if(pop!=$1) {printf("\n%s\t%d",$1,$2); pop=$1}  else printf(" %d",$2);} END {printf("\n");}'; echo xxxxxxxxxxxxxx; cat the_pops.txt) | \
  awk '/xxxxxxx/ {go=1; next} go==0 {line[$1]=$0;} go==1 {print line[$1]}' | \
   awk -F"\t" 'BEGIN {printf("Pop\tNumInferredSibships\tMeanSize\tMaxSize\tInferredSibSizes\n");} 
               {n=split($2,a,/  */); max=a[1]; sum=0.0; for(i=1;i<=n;i++) sum+=a[i]; printf("%s\t%d\t%.2f\t%d\t%s\n",$1,n,sum/n,max,$2);}' > ${RUN}_inferred_sib_sizes_summary.txt;


echo "All Done.  Output is in $(abspath $OUTD)"
