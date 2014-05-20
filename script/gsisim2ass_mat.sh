if [ $# -ne 2 ]; then
    echo "A program for converting gsi_sim output with just the -b and --self-assign options to 
an Assignment Matrix which is strictly equivalent to a GeneClass AssMat"
    echo
    echo "Syntax:"
    echo "    $(basename $0)  GsiSimFile  Cutoffs"
    echo
    echo "GsiSimFile is the file for input to gsi_sim.  Cutoff is the percentage cutoff values
required for an individual to count as assigned.  Each value should be  between 0 and 100"
    echo
    exit 1;
fi
 
 
FILE=$1
CUTOFF=$2
 
gsi_sim -b genos_gsi_sim.txt --self-assign | awk -F":" '/SELF_ASSIGN_A_LA_GC_CSV:/ {print $2}'  | awk -F";"  -v Cutoff=$CUTOFF '
$3>= Cutoff {a=$1; gsub(/[0-9]*/,"",a); print a, $2, $3}' | sed 's/\///g;' | awk '
{ 
    if( !($1 in poplist) ) {
        poplist[$1]++; npops++;  
        pops[npops]=$1;
     } 
     AssMat[$1,$2]++; 
}  
 
END {
    printf("TruePop"); 
    for(i=1;i<=npops;i++) {
       printf("\t%s",pops[i]);
    } 
    printf("\n");  
    for(i=1;i<=npops;i++) {
       printf("%s",pops[i]); 
       for(j=1;j<=npops;j++) 
           printf("\t%d",AssMat[pops[i],pops[j]]); printf("\n");  
    }  
}'
