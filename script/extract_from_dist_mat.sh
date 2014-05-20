if [ $# -ne 3 ]; then 
    echo "Syntax 
    $(basename $0)  DistMatrix  Pops  Names?

DistMatrix is a distance matrix in which:
  -It will be considered strictly white space delimited
  -any line with a # will be ignored.
  -every row starts with population identifier
   which must conform to the names uses in Pops
  -there should be no column headers, unless that line includes a #
  -the rows give a lower triangle distance matrix where the 
   columns, are, or course, ordered as the rows are.
  -After the lower triangle matrix you can have lines like:
    ADD_RESAMPLE	XbMon  BMont
   which tell us that there is a pop named XbMon in Pops
   that is in the same location as BMont but is not included
   in the distance matrix, so just use the distances from BMont
   and insert as appropriate.  This is good for those
   resampled locations.

Pops is a file with a single column that holds the population
names in the order that you want to extract them from the 
distance matrix and print out the new lower triangle.

If Names? is 0 then don't print names on the rows of the 
output.  If it is nonzero then do print the names.

The output is a lower triangle to stdout.  Names? should be 
0 for making output that is suitable for feeding back 
into Genepop to do the Isolde thing.

Note, for resamples, this thing assumes that the linear geographic distance
between then is 1.  (this means the log will be 0).  This uncomplicates
things a little bit in running genepop, and has virtually no effect if you 
are measuring things in meters, say.  But be sure that the scale that
distance is measured on is reasonable for this hack.


"
exit 1;
fi


DM=$1
POPS=$2;
NAMES=$3;



(le2unix $DM; echo;  echo "xxxxxxxxxxxxxxxxxxx"; le2unix $POPS; echo) | \
awk -v donames=$NAMES '
 NF==0 || /\#/ {next;} 
 /xxxxxxxx/ {go=1; next} 
 /ADD_RESAMPLE/ {
  if(!($3 in pops)) {
   print "Add Resample pop",$2,"is mapped to",$3,"which is not in the matrix" > "/dev/stderr"; exit;
  } 
  else {
   rep[$2]=$3;
  } next;
 } 
 go==0 {  # collect the values
  pops[$1]++; 
  rep[$1]=$1; 
  pnames[++n]=$1; 
  dist[$1,$1]=1; 
  for(i=2;i<=n;i++) {
   dist[$1,pnames[i-1]]=$i; 
   dist[pnames[i-1],$1]=$i;
  }
 } 
 go==1 {
  ++m;
  if(donames) {printf("%s\t",$1); if(m==1) printf("\n");}
  anames[m]=$1;
  if(m>1) {
   for(i=1;i<m;i++) {
    if(m==2) printf("%s",dist[ rep[$1], rep[anames[i]] ]);
    else  printf("\t%s",dist[ rep[$1], rep[anames[i]] ]);
   }
   printf("\n");
  }
 }
'