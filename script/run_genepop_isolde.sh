

if [ $# -ne 4 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile  DistMat  ThePops

The GenoFile is the file of genotypes in genepop format.
 
The DistMat is the distance matrix in the format that can be read and
processed by extract_from_dist_mat.sh

ThePops is a list of the populations in the order in which they appear
in the data set.  This is used to extract the necessary distances from 
DistMat.

MantelPerms is the number of permutations for the Mantel Test.
"

    exit 1;
fi

GENO=$1;
DIST=$2;
POPS=$3;
MANT_PERMS=$4




# make the distmat
echo "Now, preparing to make distmat.txt from $DIST";
extract_from_dist_mat.sh $DIST $POPS  0 > distmat.txt 





# now run genepop to get the Fst matrix:
# make the genepop settings first
echo "GenepopInputFile=genos_genepop.txt
MenuOptions=6.2" > GenepopSettings.txt

# then run it:
Genepop SettingsFile=GenepopSettings.txt  Mode=Batch > genepop_Fst_session.txt 




# then catenate Fst results and distmat for isolde input
cat genos_genepop.txt.MIG distmat.txt > isolde_input.txt
 



# then run isolde
# make the settings file
echo "IsolationFile=isolde_input.txt
" > IsoldeSettings.txt


# now run it multiple times with multiple settings.
# let's use 100000 Permutations for the Mantel test
for Transform in y n; do  # y=F/(1-F)  n= F 
    for GeoScale in  l d; do #  l=natural log distance    d= linear distance
	echo "Doing regression and Mantel test for Transform=$Transform and GeoScale=$GeoScale";
	(echo $Transform; echo $GeoScale; echo 1; echo $MANT_PERMS; echo) | Genepop SettingsFile=IsoldeSettings.txt >> genepop_isolde_sessions.txt;
    done
done


# after that is done, print out the fsts and the distances in a flat file
# by getting each individually and then pasting.

# here get the fsts
awk  '
 BEGIN {print "Fst"} 
 /Genetic statistic/ {go=1; next} 
 /Geographic distances:/{exit} 
 go==1 && NF>0 {for(i=1;i<=NF;i++) print $i}
' genos_genepop.txt.MIG > flat_fsts.txt


# then the distances
awk 'BEGIN {print "Dist"}  NF>0 {for(i=1;i<=NF;i++) print $i}' distmat.txt > flat_dists.txt


# then paste them together.  This will be handy for plotting them.
paste flat_fsts.txt flat_dists.txt > flat_fsts_and_dists.txt

echo;
echo "Have prepared the file flat_fsts_and_dists.txt for making a scatterplot
of Fst versus distance"

# finally, we want to summarize the results in a compact way
awk '
 BEGIN {Meth="ERROR"; DistScale="ERROR"; printf("GenDist\tLogOrLinearGeoDist\tIntercept\tSlope\tMantelPValue\n");} 
 /Fitting/ {if(match($0,/Fitting  to/)) Meth="F"; else Meth="Fover1MinusF"; if(match($0,/ln/)) DistScale="ln"; else DistScale="linear";} 
 /a =/ && /b = / {a=$3; b=$6; gsub(/,/,"",a); printf("%s\t%s\t%s\t%s",Meth,DistScale,a,b); Meth="ERROR"; DistScale="ERROR";} 
 /correlation < observed correlation/ {c=$5; gsub(/=/,"",c); printf("\t%f\n",1.0-c);}
' isolde_input.txt  > ibd_results_summary.txt 

echo
echo "Have prepared the file ibd_results_summary.txt that summarizes the
isolation by distance analyses.";
