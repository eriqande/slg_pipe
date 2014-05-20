

if [ $# -ne 1 ]; then 
    echo "$(basename $0) NumInches"
    echo "
NumInches it th approximate number of inches you would like the width of the 
distruct plots to be. 

This script will take care of running clump and distruct on everything 
in the ../arena directory.  It assumes that different dat 
files all have the same number of individuals per population
etc.

NOTE! In September of 2013 I realized that the version of distruct
I had was only good up to 5000 individuals.  I recompiled to allow for
30000 individuals, but the only source code I had was for an older version
of distruct.  I put the executable for larger samples in \"./bin/distruct_BIG\"
inside \"clump_and_distruct\".  You should symlink ./bin/distruct to that, if
desired.

"

exit 1;
fi


NumInches=$1;





# make a directory for the intermediate products
mkdir -p intermediate


# now, create the distruct input files from all the stuff in the ../arena
rm -f DataFileNames2dat00x.txt;
for i in ../arena/StructOuput_*_dat*; do 
    k=$(basename $i); 
    j=${k/StructOuput*_dat/_dat}; 
    echo "Processing $i into intermediate/dsinput$j --- a distruct input file"; 
    ./script/struct2distruct_pq.sh  $i  intermediate/dsinput$j;  
done 


# get the differnt k-values of the dsinput files (formatted 002 003 004, etc)
Kvals=$(ls intermediate/dsinput* | sed 's/.*dsinput.*_k//g; s/_.*//g;' | sort | uniq)



# then prepare the clump files, one for each value of K
rm -f GetBackToMyDataFileNames.txt;

for k in $Kvals; do 
    z=1;
    # prepare both indivq files and popq files
    ./script/distruct_input2clumpp.sh ./intermediate/dsinput_dat*_k${k}_*.indivq > ./intermediate/ClumpInput_k${k}.indivq; 
    mv xxx_num_files_xxx.txt ./intermediate/num_files_clumped_k${k}.txt; 

    # here make the popfiles
     ./script/distruct_input2clumpp.sh -p ./intermediate/dsinput_dat*_k${k}_*.popq > ./intermediate/ClumpInput_k${k}.popq; 
    mv xxx_num_files_xxx.txt ./intermediate/num_popfiles_clumped_k${k}.txt; 

    echo "Prepared ClumpInput for k = $k";  
    for i in ./intermediate/dsinput_dat*_k${k}_*.indivq; do
	j=$(basename $i);
	x=`printf "%03d" $z`
	echo "$j is clump rep $x"
	z=$((z+1));
    done >> GetBackToMyDataFileNames.txt; 
done


# then get ready to do the clumpp runs:
# pull the number of individuals from the StructureArea input
Num=$(cat ../input/N.txt);

# then cycle over the Kvals, and run clumpp with a script.
# by default here we just do the super-uber-greedy fast algorithm
# as I suspect it will work fine for all cases.
for k in $Kvals; do 
    NFiles=$(cat intermediate/num_files_clumped_k$k.txt); 
    ./script/runCLUMPP.sh intermediate/ClumpInput_k$k.indivq  intermediate/Output_${k}  $NFiles  $k  "-c $Num -m 3";
done 

# do the same for the PopQ's here
NumPops=$(cat num_pops.txt);
for k in $Kvals; do 
    NFiles=$(cat intermediate/num_files_clumped_k$k.txt); 
    ./script/runCLUMPP.sh -p intermediate/ClumpInput_k$k.popq  intermediate/Output_${k}  $NFiles  $k  "-c $NumPops -m 3";
done 


echo" 


#### DONE WITH CLUMPING INDIV Qs AND POPQs ##############


#### PROCEEDING TO DISTRUCTING   #######

"


# number of inches in a single unit of indivwidth:  0.0133550156
# xxIndivWidth_Val

# compute the indiv width:
INDWIDTH=$(echo $NumInches $Num | awk '{print $1/($2*0.0133550156)}');

# get the number of pops
NumPops=$(awk 'NF>0 {++n} END {print n}' pop_names.txt);

# set that width into the drawparams
sed "s/xxIndivWidth_Val/$INDWIDTH/g;  s/xxNumIndivs_Val/$Num/g; s/xxNumPops_Val/$NumPops/g; " drawparams_no_labels_template > drawparams_no_labels;
sed "s/xxIndivWidth_Val/$INDWIDTH/g;  s/xxNumIndivs_Val/$Num/g; s/xxNumPops_Val/$NumPops/g; " drawparams_template > drawparams;


# make drawparams for the PopQs:
awk '$2=="PRINT_INDIVS" {print $1,$2,0; next} {print}' drawparams > drawparams_popqs;
awk '$2=="PRINT_INDIVS" {print $1,$2,0; next} {print}' drawparams_no_labels > drawparams_popqs_no_labels;



# now, run distruct on everything with no label
# note that the popq files we put in there are essentially dummies, so we just set the dat and rep to 001.
for k in $Kvals; do 
    reps=$(cat intermediate/num_files_clumped_k$k.txt); 
    for((i=1;i<=$reps;i++)); do 

	# do the indivq ones
	./bin/distruct -d drawparams_no_labels  -K $k -i intermediate/Output_$k.perms_$i  \
	    -p intermediate/Output_${k}_PopQ.perms_$i  \
	    -o ds_Clumped_NoLabel_k${k}r`printf "%03d" $i`.ps ; mv ds_Clumped_NoLabel_k${k}r`printf "%03d" $i`.ps intermediate/; 

	# then do the popq ones
	./bin/distruct -d drawparams_popqs_no_labels  -K $k -i intermediate/Output_$k.perms_$i  \
	    -p intermediate/Output_${k}_PopQ.perms_$i  \
	    -o ds_Clumped_PopQ_NoLabel_k${k}r`printf "%03d" $i`.ps ; mv ds_Clumped_PopQ_NoLabel_k${k}r`printf "%03d" $i`.ps intermediate/; 
    done
done


# now, run distruct on all k's and put top labels on the first outputted perm only
for k in $Kvals; do 
    reps=$(cat intermediate/num_files_clumped_k$k.txt); 
    for((i=1;i<=1;i++)); do 

	# do the indivq ones
	./bin/distruct -d drawparams  -K $k -i intermediate/Output_$k.perms_$i  \
	    -p intermediate/Output_${k}_PopQ.perms_$i  \
	    -o ds_Clumped_TopLabel_k${k}r`printf "%03d" $i`.ps ; mv ds_Clumped_TopLabel_k${k}r`printf "%03d" $i`.ps intermediate/; 

	# then do the popq ones
	./bin/distruct -d drawparams_popqs  -K $k -i intermediate/Output_$k.perms_$i  \
	    -p intermediate/Output_${k}_PopQ.perms_$i  \
	    -o ds_Clumped_PopQ_TopLabel_k${k}r`printf "%03d" $i`.ps ; mv ds_Clumped_PopQ_TopLabel_k${k}r`printf "%03d" $i`.ps intermediate/; 
	
    done
done


# then we epsify them all and put the results in the final_eps and final_pdf folders:
mkdir final_eps final_pdf; 
for i in intermediate/ds_Clumped*; do  
    ./script/epsify_distruct.sh  $i BB;
    echo "Fixed bounding box on $i and made a PDF out of it"
done; 
mv BB*.eps final_eps/; 
mv BB*.pdf final_pdf; 

