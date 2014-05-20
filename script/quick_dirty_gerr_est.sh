

# put default values here
# VAR=default
SMALL_VAL=.005;  # set to 0 to replace small estimated values with .005


function usage {
      echo Syntax:
      echo "  $(basename $0) [-v Lo]  Num  Pop"
      echo
      echo "This script takes two column input from stdin.  The first column is the locus name and
second is the number of incompatibilities seen.  This expects to have a file in the cwd called
snppit_output_BasicDataSummary.txt from which to grab the allele freqs.  

Num is the total number of offspring assigned to parents (so we can make a fraction 
  of offspring with mendelian incompats at each locus, from the raw numbers.  

Pop is the population code to use (must match what it is in the snppit input) to
  get the allele freqs.

Givin the -v flag causes the lowest value ot Lo to be consiered.  By default, Lo
is 0.005.
"
}

if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

while getopts ":hv:" opt; do
    case $opt in
	h    ) 
	    usage
	    exit 1
	    ;;
	v    )
	    SMALL_VAL=$OPTARG
	    ;;
	#m    )  VAR=$OPTARG;
	#    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));


# uncomment to test for right number of required args
if [ $# -ne 2 ]; then
    usage;
    exit 1;
fi


NUM=$1
POP=$2

echo "Locus   MinorFreq   NumIncompats  FractIncompats  ApproxGtypErrRate"
while read locus num_inc; do
    
    # get the minor allele freq for the locus
    mfreq=$(awk -v pop=$POP -v loc=$locus '/ALLELE_COUNTSANDFREQS_SUMMARY/ && $2==pop && $3==loc {f=$7; gsub(/[^0-9.]/,"",f); if(f>.5) f=1-f; printf("%s\n",f);}' snppit_output_BasicDataSummary.txt)

    # and get the fraction of incompats:
    fract=$(echo $num_inc | awk -v num=$NUM '{print ($1*1.0)/num}')

    keep_going=1;
    g=$SMALL_VAL;
    while [ $keep_going -eq 1 ]; do
	mendrate=$(snpSumPed -p $mfreq -e $g -f 1 2 3 --ped 1 2 3 --miss-meth 0 | grep PROB_LOC_IS_INCOMPAT | awk '{print $3}');
	if (( $(echo $mendrate  $fract | awk '{if($1>=$2) print 1; else print 0}') )); then
	    keep_going=0;
	else
	    g=$(echo $g | awk '{print $1+.0005}');
	fi
	#echo "        $g  $mendrate"
    done
    #echo "    DONE! $g $mendrate ";
    echo   "$locus   $mfreq     $num_inc    $fract   $g ";
done
