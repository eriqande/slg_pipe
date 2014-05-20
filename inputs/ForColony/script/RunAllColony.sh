# defaults:
JustPrintCommands=0;
EXTRA_OPTS="";
OUTCOMM=Commands.txt;
COLLECTIONS=Collections;

function usage {
       echo Syntax:
    echo "  $(basename $0) [-o \"Opts For SimpleRunColony\"] [-f] [-d Dir] RUN Perm? NumProc"
    echo
    echo "
This script assumes you are in the ColonyArea directory and 
the Collections have all been set up and things are in order.

Namely, you have to be just above the script and the bin
directories when you launch this.

It compiles up a file of commands to use, and then it starts them up
onto NumProc cores, using GNU parallel, each one chugging through a colony 
run.

The output all goes in Collection/PopName/RUN

If Perm==1 then we permute the data before giving it to Colony.  Otherwise no.

Optional Options:

-o     :  Give this a quoted string argument, for example:
          \" -d .02 -m .01 -l 3 -L \", which are extra options to pass
          to SimpleRunColony.sh.
-f     :  Don't launch Colony! Simply compile the commands and send them
          to stdout, rather than to the file Commands.txt.
-d     :  Cycle over the directories within Dir, rather than, 
          by default, in the directory Collections.
"

}


if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

# use getopts so you can pass it -n 50, for example. 
while getopts ":o:fd:" opt; do
    case $opt in
	o    )  EXTRA_OPTS="$OPTARG";
	    ;;
	f    )  JustPrintCommands=1;
	    OUTCOMM=/dev/stdout;
	    ;;
	d    )  COLLECTIONS=$OPTARG;
	    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));




if [ $# -ne 3 ]; then
    usage;
    exit 1;
fi

RUN=$1;
Perm=$2
NP=$3


# first compile up the files:
for i in $COLLECTIONS/*; do 
    echo "echo \"Starting $(basename $i) for run $RUN at \$(date)\" >> ColonyRuns_ProgressLog.txt  ; nohup ./script/SimpleColonyRun.sh $EXTRA_OPTS $i $RUN ./input  $Perm > $i/SimpleScriptOutput_$RUN.txt; echo \"Finished  $(basename $i) for run $RUN at \$(date)\" >> ColonyRuns_ProgressLog.txt " ; 
done > $OUTCOMM;


# now spread those out
if [ $JustPrintCommands -eq 0 ]; then
    cat Commands.txt  | ./script/parallel -P $NP;
fi


