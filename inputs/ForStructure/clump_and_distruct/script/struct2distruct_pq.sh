
if [ $# -ne 2 ]; then 
    echo "Syntax:"
    echo "  $(basename $0)  StructOutput  OutfilePrefix "
    echo
    echo "StructOutput is just the path to the structure output file.
OutfilePrefix is just the prefix you want appended to the output of this 
script.  It can include a path part  like tempfiles/ds_input as long 
as the directory tempfiles exists.

"
    exit 1;


fi

ST=$1;
OUT=$2;


# first make the file of indiv qs
awk '
 /Inferred ancestry of individuals:/ {go=1; next} 
 /Inferred clusters/ {next} 
 /Estimated Allele Frequencies in/ {go=0} 
 go==1 && NF>3 {print} '  $ST | \
awk '
# this adds a serial number to each individual name to make it unique
{printf("%s %s_%d %s %s : ",$1,$2, ++n,$3,$4); for(i=6;i<=NF;i++) printf(" %s",$i); printf("\n");}
' > ${OUT}.indivq;


# then make the file of population qs
awk '
 /Proportion of membership of each pre-defined/ {go=1; next}
 /------------/ {go=0}
 go==1 && /:/ {print}
' $ST  > $OUT.popq;


