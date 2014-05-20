

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   AlleFreqFile

The AlleFreqsFile is the file of allele counts that has the following
format

INFO: LocusName PopName 
0.796875	0.140625	0.062500
[...]

This script makes something that PHYLIP's gendist program can read.  Note
that this is formatted for the \'A\' option in gendist which expects
that the frequency of all the alleles (summing to one) will be listed
for each locus.

"

    exit 1;
fi

F=$1;

awk '
NF==0 {next} 

# keep track of the pops and locs in order
$1=="INFO:" {
 loc=$2; pop=$3
 if( !(loc in locs) ) { locs[loc]++; loci[++l]=loc;}
 if( !(pop in pops) ) { pops[pop]++; popi[++p]=pop;}
 next;
}

# store everything up 
{
 line[loc,pop]=$0;
 num_alle[l]=NF;
}

# print it all out:
END {
 print "    ",p,"   ",l;
 for(i=1;i<=l;i++) printf("%d  ",num_alle[i]); printf("\n");
 for(i=1;i<=p;i++) {
  printf("%s                      \n",popi[i]);
  for(j=1;j<=l;j++) print line[loci[j],popi[i]]
 }
}
' $F;

