

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   SGL_PipeFile

The PipeFile is the standard input file for our genetics lab data pipeline

This spits out a list of the loci in order of appearance in the file
"

    exit 1;
fi

F=$1;

le2unix $F | awk '
NF==0 {next} # just ignore blank lines
m==0 { for(i=2;i<=NF;i+=2) print $i; exit} # skip the locus line
';

