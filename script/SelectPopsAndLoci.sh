 

if [ $# -ne 3 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile  PopsFile  LocsFile

The GenFile is the file of genotypes in the slg_pipe format.  PopsFile is the
file of desired populations in slg_pipe format.  LocsFile is the file of
desired loci in slg_pipe format.  

The output is another simple genotype file in slg_pipe format with only the 
pops and loci requested (in the order that they are listed) 

NOTE!  We can now drop loci and populations by merely adding a # in front of them
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
POPS=$2;
LOCS=$3;



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
') && \
((le2unix $POPS; echo;  echo xxxxxxxxxzzzzzzzzzzz; le2unix $GENO) | awk '
NF==0 || /^#/ {next}  # just ignore blank lines
/xxxxxxxxxzzzzzzzzzzz/ {go=1; m=0; next; }
go==0 {pops[$1]++} # get the pop names in a hash
go==1 && m==0 {++m; next} # skip the locus names
go==1 && m>0 {  # here we get the population name and hash it
 a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
 genopop[a]++;
}
END {
 for(i in pops) {
  if( pops[i]>1 )  toomany[i]=pops[i];
  if( !(i in genopop) ) absent[i]++;
 }
 t=0; a=0;
 for(i in toomany) {
  print "ERROR! Population",i,"appears",toomany[i],"times in the PopsFile" > "/dev/stderr";
  t++;
 } 
 for(i in absent) {
  print "ERROR! Population",i,"in PopsFile is absent from the GenoFile" > "/dev/stderr";
  a++
 }
 if(a+t) exit(1);
 else exit(0);
}
') || !(echo "FATAL ERROR in SelectPopsAndLoci.sh. Exiting..." >&2) || exit 1;





# the way we do this will not be the most efficient, since it involves
# cycling multiple times through the data set, but this is hardly 
# going to be the rate limiting step of all the analyses!

# first, get the line of locus names
le2unix $LOCS | awk 'NF==0 || /^#/ {next} {printf("\t%s\t%s",$1,$1);} END {printf("\n");}'

for pop in $(le2unix $POPS); do 
    (le2unix $LOCS; echo;  echo xxxxxxxxxzzzzzzzzzzz; echo; le2unix $GENO) | awk  -F"\t"  -v p=$pop '
NF==0 || /^#/ {next} # just ignore blank lines or commented out ones
/xxxxxxxxxzzzzzzzzzzz/ {go=1; m=0; next; }
go==0 {locs[++l]=$1} # get the locus names that we want, in order
go==1 && m==0 { for(i=2;i<=NF;i+=2)  {loccol[$i]=i;} ++m;} # get the first column of each locus
go==1 && m>0 {  # here we check to see if we are getting this population, and, if so, we do it
 a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
 if(a==p) {
  printf("%s",$1);
  for(i=1;i<=l;i++) printf("\t%s\t%s",$(loccol[locs[i]]),$(loccol[locs[i]]+1));
  printf("\n");
 }
}
'

done

