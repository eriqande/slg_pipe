

if [ $# -ne 5 ]; then
    echo "Syntax:

    $(basename $0)   GenoFile  PopsFile  LocsFile  OutDir  Settings

The GenoFile is the file of genotypes in the slg_pipe format.  PopsFile is the
file of desired populations in slg_pipe format.  LocsFile is the file of
desired loci in slg_pipe format.  OutDir is the name of the directory
into which you want all of this output to go.  It can be a relative
or absolute path.  Settings is the settings file for the analysis. slg_pipe
is distributed with a DefaultSettingsStandard.sh file in the arena directory
that you can use.

This script selects the pops from PopsFile and the loci from
LocsFile out of GenoFile and does all of our lab's standard
analyses on the resulting file.  It puts all of the results
from these analyses into the OutDir directory.

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
OUTD=$4;
SETTINGS=$5;

# a handy function for doing calls and catching errors
function DoCall {
    $CALL ||  !( (echo "FATAL ERROR attempting the call: $CALL"; echo "Exiting...") >&2) || exit 1;
}

# set up the paths
source ../script/declare_location_and_paths.sh;

# get the settings for this analysis
echo; echo;
echo "Starting a run of slg_pipe with parameters: $1 $2 $3 $4 $5"
echo "Settings from file $5 are:"
echo "------------------------------------"
CALL="cat $SETTINGS"
DoCall;
echo; echo "------------------------------------"; echo; echo;
CALL="source $SETTINGS"
DoCall;



# make the output directory
CALL="mkdir $OUTD"
DoCall;



# now do the pop selection and copy over the pop and loci files
echo "Starting population and locus selection"
CALL="SelectPopsAndLoci.sh   $GENO  $POPS  $LOCS";
DoCall > $OUTD/genos_slg_pipe.txt;  # so, this is our basic data file
awk 'NF==0 || /^#/ {next} {print}' $POPS > $OUTD/the_pops.txt;
awk 'NF==0 || /^#/ {next} {print}' $LOCS > $OUTD/the_locs.txt;
cp $LOCS $OUTD/AS_INPUT_the_locs.txt;
cp $POPS $OUTD/AS_INPUT_the_pops.txt;
cp $SETTINGS $OUTD/slg_pipe_settings.txt
echo "Created files:
    genos_slg_pipe.txt
    the_pops.txt
    the_locs.txt
And copied the $SETTINGS to $OUTD/slg_pipe_settings.txt
"


# cd into OUTD
cd $OUTD;


# now create some more input formats and get allele freqs and counts
echo "Creating more input formats and computing allele freqs, etc"
CALL="slg_pipe2gsisim.sh genos_slg_pipe.txt";
DoCall > genos_gsi_sim.txt;

CALL="gsisim2alle_counts.sh  genos_gsi_sim.txt";
DoCall > alle_counts.txt;

CALL="alle_counts2alle_freqs.sh  alle_counts.txt"
DoCall > alle_freqs.txt;

echo "Created files:
    genos_gsi_sim.txt
    alle_counts.txt
    alle_freqs.txt
"


# now, I want to do a quick check for population x locus combinations
# that have no non-missing data in them.  
echo "Scanning Data for Population-by-locus combos with no non-missing data";
awk '
 /INFO:/ {loc=$2; pop=$3; next} 
 NF>0 {sum=0; for(i=1;i<=NF;i++) sum+=$i; if(sum==0) print "All Data Apparently Missing at Locus",loc,"at population",pop}
' alle_counts.txt  > pop_by_loc_combos_missing_all.txt 

NUMCOMBOSMISS=$(wc  pop_by_loc_combos_missing_all.txt | awk '{print $1}');

if [ $NUMCOMBOSMISS -gt 0 ]; then
    echo "WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!! "
    echo "WARNING!!  There are $NUMCOMBOSMISS combinations of population and locus that have no non-missing data:"
    echo "Repeating contents of summary file pop_by_loc_combos_missing_all.txt here:"
    cat pop_by_loc_combos_missing_all.txt;
    echo
    echo "This problem will cause failure in some downstream analyses like the phylip ones"
    echo "but we are not going to terminate execution at this time."
    echo 
    echo "WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!!  WARNING!! "
    
fi


if [ $DO_GSI_SIM_STUFF -eq 1 ]; then
    # now, we are going to do some analyses with 
    # gsi_sim.  Namely we are going to count missing data
    # and do a GeneClass analysis.
    CALL="mkdir gsisim";
    DoCall;
    echo;
    echo "Preparing for analyses using gsisim"
    CALL="gsisim2missing_data_report.sh genos_gsi_sim.txt the_pops.txt the_locs.txt";
    DoCall  > gsisim/MissingDataTable.txt;
    echo "Made a table with info about missing data rates in gsisim/MissingDataTable.txt using the call:"
    echo "$CALL";
    echo
    echo "Preparing to create assignment matrices";
    for C in 0 10 20 30 40 50 60 70 80 90; do 
	CALL="gsisim2ass_mat.sh genos_gsi_sim.txt $C";
	DoCall > gsisim/AssMat_$C.txt;
	echo "Made GeneClass assignment matrix using gsisim with cutoff ${C}% in gsisim/AssMat_$C.txt";
    done;
fi;





if [ $DO_PHYLIP_STUFF -eq 1 ]; then
    # now, do the phylip stuff
    echo;
    echo "Creating directory \"phylip\" to do NJ-CSE trees and bootstrap consensus"
    echo "This is where all output for the following section will be found"; echo
    CALL="mkdir phylip";
    DoCall;
    CALL="cd phylip"
    DoCall;
    echo "Starting phylip analyses with the following call:"
    CALL="Do_phylip_cse_nj_with_boots.sh   ../alle_freqs.txt  $PhylipNBOOT";
    echo $CALL;
    echo "and redirecting its stdout to LOG_phylip_cse_nj_with_boots.txt"; echo;
    DoCall > LOG_phylip_cse_nj_with_boots.txt;
    
    # print out what we just did:
    awk '/Completed the Phylip Phase of the Standard Analysis/ {go=1} go==1 {print}' LOG_phylip_cse_nj_with_boots.txt;
    cd ..;  # be sure to back out of the directory when you are done
fi;





if [ $DO_GENEPOP -eq 1 ]; then
    # now make a genepop directory
    CALL="mkdir genepop";
    DoCall;
    echo;
    echo "Preparing for genepop analyses"
    CALL="gsisim2genepop.sh genos_gsi_sim.txt"
    DoCall > genos_genepop.txt;
    CALL="cp genos_genepop.txt genepop/"
    DoCall;
    CALL="cp $SLG_PATH/inputs/GenePopStandardSettings.txt genepop/";
    DoCall;
    CALL="cd genepop"
    DoCall;
    echo;
    echo "Have prepared directory \"genepop\" and file \"genos_genepop.txt\" for analyses
and have cd-ed into that genepop directory.  All output from genepop will
be in that directory."
    
    
    
    if [ $DO_GENEPOP_HWE -eq 1 ]; then
        # now do the Guo and Thompson HWE test
	echo "About to start HWE probability test (Guo and Thompson) for each locus"
	echo "Settings are:"
	cat GenePopStandardSettings.txt;
	CALL="Genepop SettingsFile=GenePopStandardSettings.txt MenuOptions=1.3"
	echo "Launching Genepop with the call"
	echo $CALL
	echo "and redirecting stdout output to LOG_genepop_HWE_prob_tests.txt"
	DoCall >  LOG_genepop_HWE_prob_tests.txt;
	echo "
Done with HWE tests on all loci.  Output is in \"genos_genepop.txt.P\"

"
    fi
    
    
    
    
    
    
    if [ $DO_GENEPOP_LD -eq 1 ]; then
        # now do the LD tests
	echo "About to start tests for LD at each pair of loci."
	echo "Settings are:"
	cat GenePopStandardSettings.txt;
	CALL="Genepop SettingsFile=GenePopStandardSettings.txt MenuOptions=2.1"
	echo "Launching Genepop with the call"
	echo $CALL
	echo "and redirecting stdout output to LOG_genepop_LD_tests.txt"
	DoCall >  LOG_genepop_LD_tests.txt;
	echo "
Done with LD tests on all pairs of loci.  Output is in \"genos_genepop.txt.DIS\"

";
    fi
    
    
    # finally, get out of the genepop directory
    cd ..;
fi;






if [ $PREPARE_COLONY_AREA -eq 1 ]; then
    # now prepare stuff for Colony analyses on each individual
    # collection
    echo "

Now preparing files in directory ColonyArea for running Colony later.

"
    CALL="Prepare_ColonyArea.sh  genos_slg_pipe.txt the_pops.txt the_locs.txt ColonyArea  "
    DoCall;
fi;




if [ $PREPARE_STRUCTURE_AREA -eq 1 ]; then
    # now prepare stuff for Colony analyses on each individual
    # collection
    echo "

Now preparing files in directory $StructOutDir for running Structure later.

"
    CALL="Prepare_StructureArea.sh  slg_pipe_settings.txt  genos_slg_pipe.txt  "
    DoCall;
fi;




if [ $PREPARE_FSTAT_DIR -eq 1 ]; then
    # now, make an fstat directory
    CALL="mkdir fstat";
    DoCall;
    echo;
    echo "Preparing for fstat analyses"
    CALL="cd fstat"
    DoCall;
    echo;
    CALL="slg_pipe2fstat.sh ../genos_slg_pipe.txt"
    DoCall > genos_fstat.dat;
    echo;
    cd ..; # get out of fstat directory
    echo "Have prepared directory \"fstat\" and file \"genos_fstat.dat\" for analyses.

Also in the fstat directory you will find the file \"fstat_numbers_and_pops.txt\"
which will tell you what PopIDs the numbers in fstat refer to.

Now, you can go use VMWARE or some other Windoze emulator and do the analyses you
need in fstat, operating on genos_fstat.dat. For your convenience, there is a copy 
of FSTAT in the \"pc\" directory in the slg_pipe bundle. 

Whatever you do, please save the output in the fstat directory with the default name
of \"genos_fstat.out\" this will make it easier to write scripts to summarize the output!
"
fi;




if [ $PREPARE_GENETIX_DIR -eq 1 ]; then
    # now, make a genetix directory
    CALL="mkdir genetix";
    DoCall;
    echo;
    echo "Preparing for genetix analyses"
    CALL="cd genetix"
    DoCall;
    echo;
    CALL="slg_pipe2fstat.sh ../genos_slg_pipe.txt"
    DoCall > genos_fstat4genetix.txt;
    echo;
    cd ..; # get out of the genetix directory.
    echo "Have prepared directory \"genetix\" and file \"genos_fstat4genetix.txt\" for analyses.

Now, you can go use VMWARE or some other Windoze emulator and do the analyses you
need in genetix.  To do so you will need to import the file \"genos_fstat4genetix.txt\" as an
FSTAT file into genetix. For your convenience, there is a copy of the genetix405 distribution 
in its own directory within the \"pc\" directory in the slg_pipe bundle. 

STILL NEED TO GIVE DIRECTIONS ABOUT HOW TO SAVE THE OUTPUT FILES, ETC.

"
fi;







if [ $DO_ISOL_BY_DIST -eq 1 ]; then
    # now make an isol_by_dist directory
    CALL="mkdir isol_by_dist";
    DoCall;
    echo;
    echo "Preparing for isol_by_dist analyses"
    CALL="gsisim2genepop.sh genos_gsi_sim.txt"
    DoCall > genos_genepop.txt;
    CALL="cp genos_genepop.txt isol_by_dist/"
    DoCall;
    CALL="cd isol_by_dist"
    DoCall;
    echo;
    echo "Have prepared directory \"isol_by_dist\" and file \"genos_genepop.txt\" for analyses
and have cd-ed into that isol_by_dist directory.  All output from genepop for isolation by 
distance analyses will be in that directory.  Number of permutations for the Mantel Test is
set to $IBD_MANTEL_PERMS. "
    echo;
    # now run the script
    CALL="run_genepop_isolde.sh  genos_genepo.txt  $ISOL_DISTMAT ../the_pops.txt  $IBD_MANTEL_PERMS "
    DoCall;

    echo
    echo "Done with isolation by distance analyses"

    cd ../
fi;









echo "

That concludes this run of Do_standard_analyses.sh. I hope it worked for you!
Note, to get Nei's unbiased gene diversities (He) and observed heterozygosities
(Ho) you can operate the Microsatellite Toolkit on the file 
genos_slg_pipe.txt within the output directory $OUTD within the arena 
directory.  Yay!  While you are at it, you may as well use the toolkit
to get the number of samples from each population.

I would recommend saving the Toolkit Population Statistics sheet as a 
tab delimited text file named toolkit_summary.txt in the Summarized 
directory.

Have a nice day!

"