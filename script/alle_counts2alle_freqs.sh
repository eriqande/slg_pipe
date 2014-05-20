

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   AlleCountsFile

The AlleCountsFile is the file of allele counts that has the following
format

INFO: LocusName PopName
0    3    50    4     21    0     4
[...]

This makes the very same kind of file, but the entries are 
normalized so that they sum to one.

"

    exit 1;
fi

F=$1;

awk '
NF==0 {next} 
$1=="INFO:" {print; next} 
{
 sum=0.0; for(i=1;i<=NF;i++) sum+=$i; for(i=1;i<=NF;i++) {if(sum>0) printf("%f\t",$i/(sum*1.0)); else printf("%f\t",0);} printf("\n");
}' $F;

