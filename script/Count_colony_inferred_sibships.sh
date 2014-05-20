if [ $# -ne 2 ]; then 
    echo "Syntax 
    $(basename $0)  Dir  Run

This script is intended to be run in the slg_pipe 
\"arena\" directory only.   And, of course,
you need to have already run Colony on all the 
Collections in the ColonyArea.

Dir is the directory in arena where all the 
slg_pipe output that you want to count sibships from
lives.

Run is the name of the Colony Run to draw the
results from.

This will spit back a file to stdout that has
one line for every population.  The first column is the
name of the population, and the remaining lines are the
sizes of the inferred sibships in sorted order from 
largest to smallest.

"
exit 1;
fi


DIR=$1;
RUN=$2;



POPS=$DIR/ColonyArea/the_pops.txt;


# first make a single file with all the sibships.
# note that first column in this file is index and second is the sibship 
# probability and th remaining columns are the members of
# the inferred sibship.
rm -f  ${RUN}_all_full_sibships.txt;
for i in $(cat $POPS); do 
    if [ -f $DIR/ColonyArea/Collections/$i/$RUN/${i}_${RUN}.BestFSFamily ]; then
	awk 'NR>1 {print NF-2}' $DIR/ColonyArea/Collections/$i/$RUN/${i}_${RUN}.BestFSFamily | sort -n -b -r -k 1 | awk -v pop=$i 'BEGIN {printf("%s",pop);} {printf(" %d",$1);} END {printf("\n");}';
    else
	echo "Could not file file: $DIR/ColonyArea/Collections/$i/$RUN/${i}_${RUN}.BestFSFamily. Exiting.";
	exit 1;
    fi
done;

