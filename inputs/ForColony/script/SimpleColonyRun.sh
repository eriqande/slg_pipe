
# Some default values
DROPOUTRATE="0.02";  # I set these here, but it would not be hard to set them elsewhere
MISCALLRATE="0.02"; 
NumLocToUse=0; 
UseTheLocsFile=1;
WeightedAlleFreqs=1;
RUN_LENGTH=1;
LIKE_PRECIS=1;
NUMRUNS=1;
INFERENCE_METHOD=1;
BINARY_BASENAME=colony2s.out;  # be default it uses the new colony
PolyMono="0 0"
SibPrior=0

function usage {
    echo Syntax:
    echo "  $(basename $0)  [-d DropRate -m MisRate -l NumLoc -L -f -r RunLen -p LikPre -n NumRuns -x -P PolyMono -s SibPrior -o] DIR  RUN  Inputs  Perm?"
    echo
    echo "DIR is the name of a directory where there resides a file named 
genotypes.txt.  This script creates a new directory named RUN inside
DIR and processes genotypes.txt into a Colony.dat file in RUN.  This file
includes the run options.  The Collection name is DIR.  The output name
is \"output\" because all of it is contained within a specific output directory
(DIR/RUN).  The script counts the number of individuals, etc. 

Inputs is the path to the input directory where the preamble and
the postamble live.

Perm? Is a Boolean to tell us whether we should permute the data with 
sgm_perm (if Perm==1) or not (otherwise).

This script assumes there is a file called the_locs.txt in it
that has at least the locus names in it. And also that it is being
called from a directory that has a subdirectory called \"bin\"
that holds the colony excecutable (and the binary for sgm_perm if 
doing permutations.)

This script also will wire it to:
  - do 1 run.
  - give it a random seed
  - do a run length of 1 (out of 1/2/3)
  - use likelihood precision of 1 (out of 1/2/3)
The latter two because we want to have time to do multiple runs.

The optional flag options have the following effects:

-d DropRate    :   Rate of dropout errors is set to DropRate (default 0.02)
-m MisRate     :   Miscall error rate is set to MisRate (default 0.02)
-l NumLoc      :   Use only the first NumLoc loci in the data set.
                   Note that there must be at least NumLoc loci
                   in genotypes.txt.  Typically you will want to 
                   also use -L with this so it doesn't try getting
                   locus names from a file that might not be there.
-L             :   Don't try to get locus names from the_locs.txt.  Instead
                   just use: Loc_1, Loc_2, ... NumLoc.
-f             :   Sets COLONY to NOT do allele frequency estimation that
                   takes into account the inferred sibship structure. 
                   (This script has Colony use that weighting for alle
                   freq estimation, by default.).
-r RunLen      :   Set run length to RunLen (must be 1, 2, or 3). Default is 1.
-p LikPre      :   Set Likelihood precision to LikPre (must be 1, 2, or 3).
-n NumRuns     :   Set it up to do NumRuns different runs with the data set.
-x             :   Set the inference method to Pairwise (0) rather than Full Likelihood (1)
-P PolyMono    :   Set whether males and females are polygamous.  Quoted string of two 
                   integers.  First is for males and second is for females.  
                   0 = polygmous, 1 = monogamous.  Default is both polygamous: (\"0 0\")
-s SibPrior    :   Set the prior used on the sizes of the sibships.  Default is \"0\", meaning
                   no prior.  If other choices are used, the settings are somewhat more
                   complicated. See the colony manual.  Basically you set SibPrior to the 
                   quoted string that you would want to supply.  For example, if you want a
                   medium-strength prior with average paternal and maternal sibship sizes 
                   of 4.2 and 5.3, respectively, then you would set SibPrior to 
                   the quoted string: \"2 4.2 5.3\".
-o             :   DEPRECATED. Use the old version of Colony (i.e. the 2009/2010 as opposed to 2013/2014 version)



"
}


if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

# use getopts so you can pass it -n 50, for example. 
while getopts ":d:m:l:Lfr:p:n:xP:s:o" opt; do
    case $opt in
	d    )  DROPOUTRATE=$OPTARG;
	    ;;
	m    )  MISCALLRATE=$OPTARG;
	    ;;
	l    )  NumLocToUse=$OPTARG;
	    ;;
	L    )  UseTheLocsFile=0;
	    ;;
	f    )  WeightedAlleFreqs=0;
	    ;;
	r    )  RUN_LENGTH=$OPTARG;
	    ;;
	p    )  LIKE_PRECIS=$OPTARG;
	    ;;
	n    )  NUMRUNS=$OPTARG;
	    ;;
	x    )  INFERENCE_METHOD=0;
	    ;;
  P    )  PolyMono=$OPTARG;
	    ;;
  s    )  SibPrior=$OPTARG;
	    ;;
	o    )  BINARY_BASENAME=Colony2;
	    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));


if [ $# -ne 4 ]; then
    usage;
    exit 1;
fi

DIR=$1
RUN=$2
INP=$3
PERM=$4





# get the directory in which this is being called.  This will be used to find 
# some of the other directories, etc.
CURDIR=$(pwd);

# this is designed to be run from just above the input directory
PREAMBLE=$CURDIR/$INP/ColonyCanonicalPreamble.txt;
POSTAMBLE=$CURDIR/$INP/ColonyCanonicalPostamble.txt;
CL_RAND=$CURDIR/bin/cl_rand





cd $DIR;

# make the run directory and cd into it
mkdir -p $RUN
cd $RUN


# COUNT HOW MANY FISH
NUMFISH=$( wc ../genotypes.txt | awk '{print $1}');


# count the number of loci assuming that each line in genotypes.txt has 
# an ID and then 2 columns for every locus
NUMLOCI=$(awk 'NF>0  {printf("%d",(NF-1)/2); exit}' ../genotypes.txt;)
if [ $NumLocToUse -eq 0 ]; then
    NumLocToUse=$NUMLOCI;
fi

# now create the temp file for the loci, which will be included in the 
# data set
if [ $UseTheLocsFile -eq 1 ]; then
    awk  -v NumToUse=$NumLocToUse 'NF==0 {next} n==0 {++n; printf("%s",$1); next} n>0 {if(++n<=NumToUse) printf("\t%s",$1);} END {printf("\n");}' $CURDIR/the_locs.txt  > aaatemploc;
else
    echo $NumLocToUse | awk '{printf("Loc_1"); for(i=2;i<=$1;i++)  printf("\tLoc_%d",i); printf("\n");}' > aaatemploc;
fi
echo $NumLocToUse $DROPOUTRATE $MISCALLRATE | awk '
 {printf("0"); for(i=2;i<=$1;i++) printf("\t0"); printf("\n");}  # print 0s to denote they are all codominant
 {printf("%s",$2); for(i=2;i<=$1;i++) printf("\t%s",$2); printf("\n");}  # print the DropOut Rates
 {printf("%s",$3); for(i=2;i<=$1;i++) printf("\t%s",$3); printf("\n");}  # print the Miscall Rates
' >> aaatemploc;

# bung the canonical files together while processing the data file:
( 
    sed "s/COLLECTION/$(basename $DIR)/g;
         s/OUTFIX/output/g;
         s/NUMOFFS/$NUMFISH/g;
         s/NUMLOCS/$NumLocToUse/g;
         s/SEED/$($CL_RAND -u 1 1000 9999)/g;
         s/UPDATE_FREQS/$WeightedAlleFreqs/g;
         s/NUMRUNS/$NUMRUNS/g;
         s/RUNLENGTH/$RUN_LENGTH/g;
         s/LIKE_PRECIS/$LIKE_PRECIS/g;
         s/INFERENCE_METHOD/$INFERENCE_METHOD/g; 
         s/POLY_MONO/$PolyMono/g;
         s/SIB_PRIOR/$SibPrior/g;
         " $PREAMBLE;
    cat aaatemploc;
    if [ $PERM -eq 1 ]; then
	    $CURDIR/bin/sgm_perm -N  $NUMFISH -L $NUMLOCI < ../genotypes.txt | awk -v N=$NumLocToUse '$1~/Perm_[0-9]/ {printf("%s",$1); for(i=2;i<=N*2+1;i++) printf("\t%s",$i); printf("\n");}'
    else
	    awk -v N=$NumLocToUse 'NF>0 {printf("%s",$1); for(i=2;i<=N*2+1;i++) printf("\t%s",$i); printf("\n");}' ../genotypes.txt;
    fi
    cat $POSTAMBLE;
) > Colony2.dat;


# If we are using the old version of Colony (i.e. before the stuff jinliang put in
# to reduce large full sibgroup splits) then we have to delete the inbreeding line from the Colony2.dat
if [ $BINARY_BASENAME = "Colony2" ]; then
	awk '/This option not compatible with the old version of colony/ {next} {print}' Colony2.dat > zzttuutmp
	mv zzttuutmp Colony2.dat
fi




# then start Colony and redirect output to StdoutColony.txt
# and redirect stderr there too!
$CURDIR/bin/$BINARY_BASENAME  >  StdoutColony.txt 2>&1;


# when it is done, change back to the directory you started from
cd $CURDIR

