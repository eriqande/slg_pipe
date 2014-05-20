DO_POPQ=0;


function usage {
     echo "Syntax"
    echo "  $(basename $0) [-p] ClumpInputFile  OutfilePrefix  NumberOfRuns  K   ExtraOptions "
    echo
    echo "This compiles the command line needed (and uses it) to launch CLUMPP"
    echo "on the ClumpInputFile.  It creates a parmafile and uses that for the run"
    echo "(that allows us to make a good name for the permuted output files)."
    echo
    echo "You can put more command line options to CLUMPP as a quoted string
in ExtraOptions.  If you do not have any other options just put two double 
quotes.  This is typically used to give a -m 3 option." 
    echo
    echo "The optional -p flag should be given if you are doing popq format
instead of indivq format.  In that case the output files will have PopQ appended
to them.  Using this assumes that there is a file called num_pops.txt
that has the number of populations in it.

" 
}


if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

# use getopts so you can pass it -n 50, for example. 
while getopts ":p" opt; do
    case $opt in
	p    )  DO_POPQ=1;
	    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));

if [ $# -lt 5 ]; then
  
    exit 1;
fi


# the canonical greedy algorithm paramfile for this data set
CANON=./canonical_greedy_clumpp_paramfile;


INPUT=$1
PREFIX=$2
NUMRUNS=$3
K=$4
EXTRA=$5

if [ $DO_POPQ -eq 1 ]; then 
    PREFIX=${PREFIX}_PopQ;
fi

PF=$PREFIX.$(basename $CANON)


# first we make the new paramfile:
if [ $DO_POPQ -eq 0 ]; then 
    awk -v p="$PREFIX.perms" -v numruns=$NUMRUNS  '$1=="PERMUTED_DATAFILE" {print $1,p; next} $1=="R" {print $1,numruns; next}  {print}' $CANON > $PF;
    CALL="./bin/CLUMPP $PF  -i $INPUT    -o $PREFIX.outfile -k $K  -j $PREFIX.miscfile  $EXTRA"
fi

if [ $DO_POPQ -eq 1 ]; then 
    awk -v p="$PREFIX.perms" -v numruns=$NUMRUNS  '$1=="PERMUTED_DATAFILE" {print $1,p; next} $1=="DATATYPE" {print $1,1; next} $1=="R" {print $1,numruns; next}  {print}' $CANON > $PF;
    CALL="./bin/CLUMPP $PF  -p $INPUT    -o $PREFIX.outfile -k $K  -j $PREFIX.miscfile  $EXTRA"
fi

# then we run CLUMPP
echo Doing Call: $CALL;
$CALL;



