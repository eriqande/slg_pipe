DO_POPQ=0;


function usage {
    echo "Syntax"
    echo "  $(basename $0) [-p] File1 File2 File3 ..."
    echo
    echo "This catenates all the indivq files which are formatted for distruct"
    echo "into a single file (on stdout) formatted for clumpp.  It also "
    echo "writes the number of files it has processed into the file "
    echo "xxx_num_files_xxx.txt"
    echo
    echo "The optional -p flag should be given if you are supplying popq files
instead of indivq files to this script.  Then it will format them 
correctly.  It will also put a file called num_pops.txt in the current working
directory.  it tells you how many pops there are.


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


if [ $# -eq 0 ]; then
    usage;
    exit 1
fi

CNT=0

# cycle over the input files
while (( "$#" )); do
    FILE=$1;
    if [ $DO_POPQ -eq 0 ]; then
	awk 'NF>0 {printf("%s %d  ",$1,++n); for(i=3;i<=NF;i++) printf(" %s ",$i); printf("\n");}' $FILE;
    fi
    if [ $DO_POPQ -eq 1 ]; then
	awk 'NF>0' $FILE | wc | awk '{print $1}' > num_pops.txt;
 	cat $FILE;
    fi
    echo; 
    echo;

    shift;  # get the next file
    
CNT=$(( $CNT + 1 ));
done


echo $CNT > xxx_num_files_xxx.txt;

