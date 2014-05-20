

if [ $# -ne 3 ]; then
    echo "Syntax:

    $(basename $0)   GsiSimFile  PopsFile   LocsFile

The GsiSimFile is the file of genotypes in gsi_sim format. Recall that 
missing data is denoted by a 0.  PopsFile is the file with the IDs of the
pops in order that you want them in.   LocsFile is the same with 
the Loci.

The output to stdout is a tab delimited table with pops as the rows and
loci as the columns.  After the headers the first row is the ALL_POPS row
and the first column is the ALL_LOCI row.  The entries in each cell are the 
fraction of missing data at each pop by locus combination.

"

    exit 1;
fi

GF=$1;
PF=$2;
LF=$3;

(awk '{print "xxGETPOPS:",$1}' $PF; awk '{print "xxGETLOCS:",$1}' $LF; gsi_sim -b $GF) |
awk '
/xxGETPOPS:/ {pops[++p]=$2; next}
/xxGETLOCS:/ {locs[++l]=$2; next}

/IND_COLL_SUMMARY_missing_data_report:/ {
 fract[$3,$7]=$NF;  # $3 is pop name, $7 is locus name
 locN[$7]+=($5*2); # the number of gene copies attempted to genotype at this locus
 locMiss[$7]+=($5*2 - $9);  # the number of gene copies missing (number attempted minus number non missing)
 popN[$3]+=($5*2);  # total number of gene copies (at all loci) attempted to genotype in this pop
 popMiss[$3]+=($5*2 - $9);  
 totN+=($5*2);
 totMiss+=($5*2 - $9); 
 popSamSize[$3]=$5;  # just the number of individuals in this collection
}

END {
# get the total number of indivs:
NIndiv=0; for(i in popSamSize) NIndiv+=popSamSize[i];

# put the header on there:
printf("\tNumIndivs\tALL_LOCI");
for(i=1;i<=l;i++) printf("\t%s",locs[i]); 
printf("\n");

# then put the ALL_POPS row in there:
printf("ALL_POPS\t%d\t%.3f",NIndiv,totMiss/(totN*1.0));
for(i=1;i<=l;i++) printf("\t%.3f",locMiss[locs[i]]/(locN[locs[i]]*1.0)); 
printf("\n");


# then put each other row in there:
for(j=1;j<=p;j++) {
 printf("%s\t%d\t%.3f",pops[j],popSamSize[pops[j]],popMiss[pops[j]]/(popN[pops[j]]*1.0));
 for(i=1;i<=l;i++) printf("\t%.3f",fract[pops[j],locs[i]]); 
 printf("\n"); 
}

}
'

