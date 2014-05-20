

# put default values here
# VAR=default



function usage {
      echo Syntax:
      echo "  $(basename $0)  RepoFile  GenoFile 

INPUT:

RepoFile is the path to a TAB-delimited file of meta data straight from the repository. The
first column has to be the NMFS_DNA_ID.  As currently implemented, results might not 
be great if this is a text file made by a PC version of Excel.  This can be fixed easily
later.  BIG NOTE!! The column that holds the NMFS_DNA_ID has in the RepoFile has got to be named 
\"NMFS_DNA_ID\". It is NOT ACCEPTABLE to name that column something else, like
\"NMFS Rep ID\" or \"NMFS_Rep_ID\".

GenoFile is the path to a file of genotypes in TAB-delimited two column format.  The
first column of this has to be the sample name in the format:

NMFSID_whatever

In other words, the NMFS ID has to be the first part of the name and must be 
followed by an underscore (or nothing, if the name is just the NMFS ID). And then 
can be followed by anthying else.  For example:

M003195_M018_2B_3007_A003

would be allowable, while these would not be:
M003195M018_2B_3007_A003
M003195%M018_2B_3007_A003
M018_2B_3007_A003_M003195
etc....

OUTPUT:

This script produces three, separate, TAB-delimited files in the current working directory:

1) Merged.txt: a file consisting of one line for every individual sample found (by its
     NMSF ID) in both the repository file and the genotypes file.  An extra column
     is added (column 2) which contains the index of the genotype for samples that
     have been regnotyped.  The indices for such regenotypes will be in increasing
     order according to the input order of the genotypes in the GenoFile.

2) MetaLackingGenos.txt: a file with one line for every line of the RepoFile for which 
     no genotypes were found in the GenoFile.

3) GenosLackingMeta.txt: a file with one line for every line of the GenoFile for which
     no meta data was found in the RepoFile.

Some progress reports and other stuff are printed to stdout.

";

}

if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

while getopts ":h" opt; do
    case $opt in
	h    ) 
	    usage
	    exit 1
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
if [ $# -ne 2 ]; then
    usage;
    exit 1;
fi


REPO=$1;
GENO=$2;


# note that I have the awk 'NF>0' in there because these files 
# created by Excel don't have a final line break!
RLINES=$(le2unix $REPO | awk 'NF>0' | wc | awk '{print $1}');
GLINES=$(le2unix $GENO | awk 'NF>0' | wc | awk '{print $1}');


echo "Starting execution at $(date)"
echo "Directory = $(pwd)"
echo "RepoFile = $REPO and has $RLINES lines"
echo "GenoFile = $GENO and has $GLINES lines"
echo


(le2unix $GENO; echo; echo "xxxxxxxxxxxxzzzzzzzzzzzzzz"; le2unix $REPO; echo) | awk -F"\t" '
BEGIN {OFS="\t"}
NF==0 {next}  # if there is a line with nothing on it, skip it.  Note that we have an echo after le2unixing both GENO and REPO in case they have no final line ending.
n==0 {get_header=1}
get_header==1 {
 if(go==0) {
  genohead=$0;
  genonf=NF; 
 }
 else {
  repohead=$0;
  repohead_plus=repohead;
  sub(/NMFS_DNA_ID/,"NMFS_DNA_ID\tGENOTYPE_NUMBER",repohead_plus);
  reponf=NF;
 }
 get_header=0;
 n++;
 if(go==1) { # at this point we have both the genohead and the repohead
  print repohead > "MetaLackingGenos.txt";
  print "GENOTYPE_NUMBER",genohead > "GenosLackingMeta.txt";
  print repohead_plus,genohead > "Merged.txt";
 }
 next;
}
/xxxxxxxxxxzzzzzzzzzzz/ {n=0; go=1; next}
go==0 { # get the genotype data
 split($1,a,/_/);
 id=a[1];
 gsub(/  */,"",id); # get rid of any spaces
 genorep[id]++;  # add one to the number of times this guy has been genotyped.
                 # this is keyed off NMFS_ID.
 geno[id,genorep[id]]=$0;  # simple, just store it in a line keyed by NMFS_ID and the rep.
}
go==1 { # process each repo line.  If the geno exists, catenate and print to Merged, and record that
        # that geno was found in the repo.  The only ugly part here is making enough tabs where
        # they have been dropped off the end of lines.
 
 # make a tab-pad string.  This includes at least one for separating things.
 pad="\t";
 #print $1,NF;
 for(i=NF;i<reponf;i++) {
  pad = sprintf("%s\t",pad);
  #print "    adding a tab";
 }
 nmfsid=$1;
 gsub(/  */,"",nmfsid); # get rid of any spaces
 has_meta[nmfsid]++;

 if(nmfsid in genorep) {
  for(i=1;i<=genorep[nmfsid];i++) {
   $1 = sprintf("%s\t%03d",nmfsid,i);
   print $0 pad geno[nmfsid,i] > "Merged.txt";
  }
 }
 else {
  print $0 > "MetaLackingGenos.txt";
 }
}

# down here we check to see if any of the genos had no meta
END {
 for(i in genorep) {
  if(!(i in has_meta)) {
   for(j=1;j<=genorep[i];j++) {
    printf("%03d\t%s\n",j,geno[i,j]) > "GenosLackingMeta.txt";
   }
  } 
 }
}
'

MLINES=$(le2unix Merged.txt | wc | awk '{print $1}');
GLMLINES=$(le2unix GenosLackingMeta.txt | wc | awk '{print $1}');
MLGLINES=$(le2unix MetaLackingGenos.txt | wc | awk '{print $1}');

echo "Output files:
   Merged.txt with $MLINES lines
   GenosLackingMeta.txt with $GLMLINES lines
   MetaLackingGenos.txt with $MLGLINES lines

"
PRE=$((RLINES + GLINES - 2))
POST=$(( 2*(MLINES-1) + GLMLINES + MLGLINES - 2))

echo "If #File = number of lines in file File, then a good check is that:

#GenoFile-1 + #MetaFile-1  =  $PRE

should be equal to:

2*(#Merged.txt-1) + #GenosLackingMeta.txt-1 + #MetaLackingGenos.txt-1 = $POST

"
echo "Completed execution at $(date)"
