

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   GsiSimFile

The GsiSimFile is the file of genotypes in gsi_sim format. Recall that 
missing data is denoted by a 0.

The output is a file with allele counts that has lines like:

INFO: LocusName PopName

which are then followed by the allele counts.  This will make
it easy to manipulate in awk.

 "

    exit 1;
fi

GF=$1;

gsi_sim -b $GF | awk '
/IND_COLL_SUMMARY_popfreqsum: LOCUS=/  {split($2,a,/=/); locus=a[2];} 
/IND_COLL_SUMMARY_popfreqsum: Pop=/ {split($2,a,/=/); pop=a[2]; print "INFO:",locus,pop; for(i=3;i<=NF;i+=2) printf("%s\t",$i); printf("\n");
}'

