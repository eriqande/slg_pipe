

if [ $# -ne 3 ]; then
    echo "Syntax:

    $(basename $0)   NewickTrees  NumBoot  CutOff

NewickTrees is a file consistings of series of trees in newick format from phylip.  The first
tree should be the consensus bootstrap tree.  The following trees should
be trees with branch lengths that you want to adorn with bootstrap values at the 
appropriate place as well.   They can have line endings at the end of some of the lines, 
and even white space within them (this script will zap that) but the trees must be terminated
by semicolons. 

NumBoot is the number of bootstrap replicates.

CutOff is the PERCENTAGE  (i.e. between 0 and 100) bootstrap value below which
you don't want to include the bootstrap value on the resulting trees.


The output is all the trees including the first in which the bootstrap values (>=CutOff)
for each subtree have been included (as a percentage, i.e. between 0 and 100) within
square brackets.  Dendroscope can read these and label the appropriate nodes/branches
with these values.

Note that SLG_PATH must be defined and point to the directory above the script
directory that contains
subtree_grabber.awk

"
    exit 1;
fi

TREEGRABBER=$SLG_PATH/script/subtree_grabber.awk;

FILE=$1
NumBoot=$2
CUT=$3;

# first, get rid of the line endings by tr-ing them into spaces and
# then sedding those away. Also get rid of tabs if there are any:
tr '\n' ' ' < $FILE | tr '\t' ' ' | sed 's/ *//g;' | awk  -v NUMBOOT=$NumBoot  -v cutoff=$CUT -f $TREEGRABBER
