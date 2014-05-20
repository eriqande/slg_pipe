

if [ $# -ne 4 ]; then
    echo "Syntax:

    $(basename $0)   TabDelimPopNamesFile  A B   NewickFile

This replaces names in a Newick file.  

TabDelimPopNamesFile is a TAB-delimited file of names.  In column 
A is the name as it appears in the NewickFile and in column B
is the name as you would like to change it to.  Note that it might
not make sense to change the names to something with a space in it,
as the tree viewers might bomb.  

NewickFile is a Newick formatted file like those produced by 
phylip.

This script operates by creating a list of substitutions for sed
to operate on.  This list is in the file xxx_sedinput  

"

    exit 1;
fi


Names=$1
A=$2
B=$3
Newick=$4

le2unix $Names | awk -F"\t"  -v a=$A -v b=$B '
 {printf("s/\\([^a-zA-Z0-9]\\)%s\\([^a-zA-Z0-9]\\)/\\1%s\\2/g;\n",$a,$b);}
' > xxx_sedinput;

sed -f xxx_sedinput $Newick;




