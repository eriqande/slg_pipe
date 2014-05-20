

if [ $# -ne 2 ]; then
    echo "Syntax:

    $(basename $0)   SGL_PipeFile  ShortyNamesFile

The PipeFile is the standard input file for our genetics lab data pipeline,
but it might have some pop names that are too long.

The ShortyNamesFile is a simple text file with two whitespace delimited
columns.  The first column holds the current pop name and the second column
holds what you want to change it to. This could be useful when you need
to make a shorter name.  There have to be two columns on each line!!!

This doesn't check to make sure that you are not assigning two different
populations to the same name (since this might be something you want to do
if you want to merge populations.).

This does not reorder the populations or the individuals in the file at all.
"

    exit 1;
fi

F=$1;
S=$2;


(le2unix $S; echo "xxxxxxxxxxxxxxxxxxxxx"; le2unix $F) |awk '
NF==0 {next} # just ignore blank lines
/xxxxxxxxxxxxx/ {go=1; next}
go==0 {rep[$1]=$2;}
go==1 && m==0 { ++m; print; next} # just print the locus line
go==1 && m>0 { 
 a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
 b=$1; gsub(/[^0-9]*/,"",b); # get the numbers be removing everything else
 printf("%s%s",rep[a],b);
 for(i=2;i<=NF;i++) printf("\t%d",$i);
 printf("\n");
}
';

