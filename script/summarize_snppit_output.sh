


# put default values here
# VAR=default
RestrictToPop=0;
POP="Unset"
MatchOffs=0;
OffMatch=Not_Set_Here_Now;

function usage {
      echo Syntax:
      echo "  $(basename $0) [-o OffMatch] [-p Pop] Dir  FDR"
      echo
      echo "Dir is the directory where all of the snppit output resides.

FDR is the false discovery rate value that you will accept as a good cutoff. 
Currently this only makes sense for a single parental population.  This cutoff
can be found by looking at the FDR summary and figuring out what a good value would 
be.

OffMatch is a pattern that offspring must match to be counted

Pop is the name of the pop to restrict parentage to.

The script does a bunch of stuff that I will describe later...
"
}

if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

while getopts ":p:o:h" opt; do
    case $opt in
	p    )  POP=$OPTARG;
	    RestrictToPop=1;
	    ;;
	h    ) 
	    usage
	    exit 1
	    ;;
	o    )  OffMatch=$OPTARG;
	    MatchOffs=1;
	    ;;
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

DIR=$1
FDR=$2


# these are just to send the column numbers to awk.
# hard wired now, but could be made more flexible later.
# I also will throw the info in there to try to restrict
# to different popuations.  This is sort of a hack, but I 
# in a hurry to add that.
COLS=" -v cOffColl=1 
-v cKid=2
-v cPa=3
-v cMa=4
-v cPop=5
-v cSpwnYr=6
-v cFDR=7
-v cMaxR=12
-v cNePairs=16
-v MItrio=22
-v MILoc=23 
-v rPop=$POP
-v rToPop=$RestrictToPop
-v OffMatch=$OffMatch
-v MatchOffs=$MatchOffs"


# now we get a list of the offspring collections
COLLECTIONS=$(awk $COLS -F"\t" 'NR>1 {n[$(cOffColl)]++} END {for(i in n) print i}' $DIR/snppit_output_ParentageAssignments.txt | sort);


# now cycle over the collections and do a bunch of summaries:
for C in  $COLLECTIONS; do
    echo; echo
    echo "**************************************************"
    echo "  Summary for Offspring Collection $C"
    echo "**************************************************"
    echo "Parent Pop Restricted to: $POP"
    echo "Offspring Restricted to matching: $OffMatch"
    echo
    echo

    # just the raw numbers assigned versus not to parent pairs
    awk -v C=$C -v FDR=$FDR  $COLS '{the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se"  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) {ass++;} else {nass++}} END {
printf("NumAssigned:    %d\nNumNotAssigned: %d\nTotal:          %d\n\n",ass,nass,ass+nass);}'   $DIR/snppit_output_ParentageAssignments.txt

    # The year-classes of the fish assigned to parents
    echo;
    echo "Amongst offspring assigned to parents, the number conceived in different years"
    awk -v C=$C -v FDR=$FDR  $COLS '{the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se"  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) n[$cSpwnYr]++} END {for(i in n) printf("%s   %d\n",i,n[i])}' $DIR/snppit_output_ParentageAssignments.txt | sort -n -b -k 1
    echo;


    # distribution of number of mendelian compatible parents
    echo
    echo "Amongst offspring assigned to parents, the number of possible parent pairs"
    echo "not excluded by SNPPIT's Mendelian incompatibility criterion"
    echo "NumNonExcPairs  NumTimes"
    awk -v C=$C -v FDR=$FDR  $COLS '{the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se"  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) {np[$cNePairs]++; }} END {for(i in np) print i,np[i];}'   $DIR/snppit_output_ParentageAssignments.txt | sort -n -b -k 1
    echo
    echo

     # now, we create some files summarizing how many offspring different pairs produce
    awk -v C=$C -v FDR=$FDR  $COLS 'BEGIN {SUBSEP="   "} {the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se"  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) n[$cPa,$cMa]++} END {for(i in n) print i,n[i]}'  $DIR/snppit_output_ParentageAssignments.txt | sort -n -b -r -k 3 > $POP.$OffMatch.ParPair_summaries_$C.txt 


    # then we summarize each of those:
    echo "Distribution of number of offspring per parent pair";
    echo "NumOffspring   NumParentPairs"
    awk '{n[$3]++} END {for(i in n) printf("%d    %d\n",i,n[i])}' $POP.$OffMatch.ParPair_summaries_$C.txt | sort -n -b -k 1

    # distribution of number of mendelian incompats amongst inferred parents
    echo
    echo "Amongst offspring assigned to parents, the number of mendelian incompats with the pair"
    awk -v C=$C -v FDR=$FDR  $COLS '{the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se"  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) {nMI[$MItrio]++; }} END {for(i in nMI) print i,nMI[i];}'   $DIR/snppit_output_ParentageAssignments.txt | sort -n -b -k 1
    echo
    echo "How often different loci are involved in incompatibilities"
    awk -v C=$C -v FDR=$FDR  $COLS '{the_offs_match=match($2,OffMatch); } NR>1 && $cOffColl==C && (MatchOffs==0 || (MatchOffs==1 && the_offs_match)) {if($cFDR<FDR && $cMaxR=="C_Se_Se" && $MItrio>0  && (rToPop==0 || (rToPop==1 && $cPop==rPop))) {n=split($MILoc,locs,/,/); for(i=1;i<=n;i++) cnt[locs[i]]++;}} END {for(i in cnt) printf("%s\t%d\n",i,cnt[i]);}'   $DIR/snppit_output_ParentageAssignments.txt | sort -n -r -b -k 2;
    echo
    echo

   
 
    
# awk -v C=$C -v FDR=$FDR  $COLS 'NR>1 {if($cFDR<FDR && $cMaxR=="C_Se_Se") {nass++; nMI[$MItrio]++; } 
done

