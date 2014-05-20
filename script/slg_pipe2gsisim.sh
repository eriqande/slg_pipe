

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile

The GenoFile is the file of genotypes in the slg_pipe format. 

The output is a gsi_sim file "

    exit 1;
fi

GENO=$1;


le2unix $1 | awk -F"\t" '
 NF==0 {next} # skip any blank lines
 m==0 {for(i=2;i<=NF;i+=2) print $i; m++; next} # print the loci
 m>0 { # down in the geno data
  a=$1; gsub(/[0-9]*/,"",a);  # get the pop name by removing numbers
  if( !(a in poplist) ) { print "POP",a; poplist[a]++}
  print;
 }
'  > xxxtempxxx

# get the number of samples and loci
NS=$(awk 'NF>2 {ns++} END {print ns}' xxxtempxxx);
NL=$(awk 'NF==1 {nl++} END {print nl}' xxxtempxxx);

# now catenate into a gsi file:
(echo $NS $NL; cat xxxtempxxx);

rm -f xxxtempxxx;


