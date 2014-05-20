

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   SGL_PipeFile

The PipeFile is the standard input file for our genetics lab data pipeline

This spits out a list of the pops in order of appearance in the file
"

    exit 1;
fi

F=$1;

le2unix $F |awk '
NF==0 {next} # just ignore blank lines
m==0 { ++m; next} # skip the locus line
m>0 { 
 a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
 if( !(a in pops)) {print a; pops[a]++}
}
';

