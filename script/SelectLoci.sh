

# put default values here
LCOL=2;  # bey default, assume the first locus column is column 2



function usage {
      echo Syntax:
      echo "  $(basename $0) [-c FirstLocCol] LocFile  GenoFile"
      echo
}

if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

while getopts ":c:h" opt; do
    case $opt in
	m    )  LCOL=$OPTARG;
	    ;;
	h    ) 
	    usage
	    exit 1
	    ;;

	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));


# uncomment to test for right number of required args
#if [ $# -ne 4 ]; then
#    usage;
#    exit 1;
#fi



# uncomment to process a series of remaining parameters in order
#while (($#)); do
#    VAR=$1;
#    shift;
#done
