

# put default values here
PRESERVE=0



function usage {
      echo "Syntax:"

echo "    $(basename $0)  [-p] GSI_SimFile

The GSI_SimFile is the file of genotypes in the gsi_sim format. 

The output is a genepop file in one-column (6 digit) format 

the -p option causes numbers in the names of the individuals to not
be removed.

"


}

if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

while getopts ":hp" opt; do
    case $opt in
	h    ) 
	    usage
	    exit 1
	    ;;
	p    ) 
	    PRESERVE=1;
	    ;;
	#m    )  VAR=$OPTARG;
	#    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));


# uncomment to test for right number of required args
if [ $# -ne 1 ]; then
    usage;
    exit 1;
fi


GENO=$1;


awk -v preserve_numbers=$PRESERVE '
 NF==0 {next}
 # at the first line print the title line
 m==0 {m++; print "Title Line: File converted from a gsi sim file.  NumInds=",$1,"NumLoc=",$2; next} 

 NF==1 {print; next} # print out the loci

 $1=="POP" {print $1; next}

 # every other line, we strip the numbers off the indiv ID and then print the loci
 {
  a=$1;
  if(preserve_numbers==0) {
    gsub(/[0-9]*/,"",a);
  }
  printf("%s , ",a);
  for(i=2;i<=NF;i+=2) {
   c[1]=$i;
   c[2]=$(i+1);
   printf(" ");
   for(j=1;j<=2;j++)  {
    pad="";
    if(c[j]<10) pad="00";
    else if(c[j]<100) pad="0";
    printf("%s%d",pad,c[j]);
   }
  }
  printf("\n");
 }
' $GENO;


