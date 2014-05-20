 

if [ $# -ne 2 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile   LocsFile

The GenoFile is the file of genotypes in the slg_pipe format,
but in this case the pop names do not have to conform to slg_pipe
specifications. So, this works on any two-column file type thing.

LocsFile is the file of desired loci in slg_pipe format.  

The output is another simple genotype file in slg_pipe-like format with only the 
loci requested (in the order that they are listed) 

NOTE!  We can now drop loci by merely adding a # in front of them
AT THE VERY BEGINNING OF THE LINE THAT THEY ARE ON in the LocsFile or
the PopFile. For example:

OtsG43
#Ssa85
Oki23

will drop Ssa85.  However this:

OtsG43
 #Ssa85
Oki23

Will just cause endless headaches and fatal errors.


"

    exit 1;
fi



GENO=$1;
LOCS=$2;



# First, check to make sure that the locus names and pop names correspond to things
# that are actually in the data set and none are used twice
((le2unix $LOCS; echo;  echo xxxxxxxxxzzzzzzzzzzz; echo; le2unix $GENO) | awk '
NF==0 || /^#/ {next}  # just ignore blank lines or lines starting with # so you can comment them out.
/xxxxxxxxxzzzzzzzzzzz/ {go=1; m=0; next; }
go==0 {n[$1]++}
go==1 && m==0 { 
 for(i=2;i<=NF;i+=2)  {loccol[$i]=i; m++} 
 for(i in n) {
  if(n[i]>1) toomany[i]=n[i];
  if( !(i in loccol) ) absent[i]++;
 }
 t=0; a=0;
 for(i in toomany) {
  print "ERROR! Locus",i,"appears",toomany[i],"times in the LocsFile" > "/dev/stderr";
  t++;
 } 
 for(i in absent) {
  print "ERROR! Locus",i,"in LocsFile is absent from the GenoFile" > "/dev/stderr";
  a++
 }
 if(a+t) exit(1);
 else exit(0);
} 
')

# the way we do this will not be the most efficient, since it involves
# cycling multiple times through the data set, but this is hardly 
# going to be the rate limiting step of all the analyses!

# first, get the line of locus names
le2unix $LOCS | awk 'NF==0 || /^#/ {next} {printf("\t%s\t%s",$1,$1);} END {printf("\n");}'


(le2unix $LOCS; echo;  echo xxxxxxxxxzzzzzzzzzzz; echo; le2unix $GENO) | awk  -F"\t"  '
	NF==0 || /^#/ {next} # just ignore blank lines or commented out ones
	/xxxxxxxxxzzzzzzzzzzz/ {go=1; m=0; next; }
	go==0 {locs[++l]=$1} # get the locus names that we want, in order
	go==1 && m==0 { for(i=2;i<=NF;i+=2)  {loccol[$i]=i;} ++m; next} # get the first column of each locus
	go==1 && m>0 {  # now, get the info for an individual
	printf("%s",$1);
	for(i=1;i<=l;i++) printf("\t%s\t%s",$(loccol[locs[i]]),$(loccol[locs[i]]+1));
	printf("\n");
	}
'


