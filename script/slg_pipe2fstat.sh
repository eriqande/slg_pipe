

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile

The GenoFile is the file of genotypes in the slg_pipe format. 

The output is an fstat file (to stdout) and a file with a list
of the numbers that correspond to which population codes named
fstat_numbers_and_pops.txt
 "

    exit 1;
fi

GENO=$1;



# when we process the file we will keep track of:
#  nl -- the number of loci
#  np -- the number of collections ("pops" or "samples")
#  nu -- the highest number used to label an allele
# and then we will put those (along with a 3) on the top of the 
# resulting file.
le2unix $1 | awk -F"\t" '
 NF==0 {next} # skip any blank lines
 m==0 {for(i=2;i<=NF;i+=2) {print $i; ++nl} m++; next} # print the loci
 m>0 { # down in the geno data
  a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
  if( !(a in poplist) ) { 
   print ++np,a > "fstat_numbers_and_pops.txt"; 
   poplist[a]++;
  }
  printf("%d  ",np);
  for(i=2;i<=NF;i+=2) {
   c[1]=$i;
   c[2]=$(i+1);
   if(c[1]>nu) nu=c[1];
   if(c[2]>nu) nu=c[2];
   printf(" ");
   if(c[1]==0 || c[2]==0) {
    printf("     0");
   }
   else {
    for(j=1;j<=2;j++)  {
     pad="";
     if(c[j]<10) pad="00";
     else if(c[j]<100) pad="0";
     printf("%s%d",pad,c[j]);
    }
   }
  }
  printf("\n");

 }


END {
 print np,nl,nu,3 > "yyytempyyy"; 
}
'  > xxxtempxxx


# now catenate those into an fstat file while putting PC line endings on them
(le2pc yyytempyyy; le2pc xxxtempxxx);

rm -f xxxtempxxx yyytempyyy;


