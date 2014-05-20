

if [ $# -ne 1 ]; then
    echo "Syntax:

    $(basename $0)   Which 

This script is designed to be run from the arena directory
directly under slg_pipe.

This will look at all the output in the SLG_PIPE output directory
Which and will create summaries of the output (as Eric has seen fit)
and put those summaries in the directory \"Summarized\" within the 
Which directory.  It will create \"Summarized\" if necessary.  

Obviously, Do_standard_analysis.sh should have already been run to
create the output in Which.

Many of the results of this script will be input to R scripts for making
plots and things.

 "

    exit 1;
fi


WHICH=$1;
OUTD="Summarized";

# set up the paths
source ../script/declare_location_and_paths.sh;


cd $WHICH || exit 1;
mkdir -p $OUTD;



F=genepop/genos_genepop.txt.P
if [ -f $F ]; then 

    # first get the flat file
    (awk '
      BEGIN {code["switches"]="s"; code["matrices"]="m"; printf("Locus\tPop\tPvalue\tStdErr\tWeirCockFis\tRandHFis\tSteps\tSwitchesOrMatrices\n");}
      /Results by population/ {exit} 
      $1=="Locus" {loc=$2; gsub(/"/,"",loc);}  
      $NF=="switches" || $NF=="matrices" {printf("%s",loc); for(i=1;i<=NF;i++) {if($i=="-") printf("\t0.000"); else if(i==NF) printf("\t%s",code[$i]); else  printf("\t%s",$i);} printf("\n");}
      ' $F > $OUTD/HWE_flatfile_genepop.txt) && echo "Summarized HWE results in $F into  $OUTD/HWE_flatfile_genepop.txt";  

     # then get the proportion of significant tests for each population
    ((echo Pop; cat the_pops.txt) > $OUTD/HWE_perc_signif_tests_pops.txt;
    for C in .0001 .001 .01 .025 .05 .1; do
	(cat $OUTD/HWE_flatfile_genepop.txt; echo "xxxxxxxxxxxxxxxxxx"; cat the_pops.txt) | \
	    awk -v c=$C  'BEGIN {printf("HWD.at%s\n",c);} /xxxxxxxxxxx/ {go=1; next} NR>1 && go==0 { if($3<c) x[$2]+=1.0; n[$2]+=1.0;} go==1 {if($1 in n) printf("%.1f\n",100.0*x[$1]/n[$1]); else printf("NA\n");}' | \
	    paste $OUTD/HWE_perc_signif_tests_pops.txt - >> temp;
	mv temp $OUTD/HWE_perc_signif_tests_pops.txt;
    done;) && echo "Summarized HWE results into $OUTD/HWE_perc_signif_tests_pops.txt"


     # and get the proportion of significant tests for each locus
    ((echo Locus; cat the_locs.txt) > $OUTD/HWE_perc_signif_tests_locs.txt;
    for C in .0001 .001 .01 .025 .05 .1; do
	(cat $OUTD/HWE_flatfile_genepop.txt; echo "xxxxxxxxxxxxxxxxxx"; cat the_locs.txt) | \
	    awk -v c=$C  'BEGIN {printf("HWD.at%s\n",c);} /xxxxxxxxxxx/ {go=1; next} NR>1 && go==0 { if($3<c) x[$1]+=1.0; n[$1]+=1.0;} go==1 {if($1 in n) printf("%.1f\n",100.0*x[$1]/n[$1]); else printf("NA\n");}' | \
	    paste $OUTD/HWE_perc_signif_tests_locs.txt - >> temp;
	mv temp $OUTD/HWE_perc_signif_tests_locs.txt;
    done;) && echo "Summarized HWE results into $OUTD/HWE_perc_signif_tests_locs.txt"

else
    echo "No File $F so no HWE summaries";
fi



F=genepop/genos_genepop.txt.DIS
if [ -f $F ]; then 

    # first get the flat file
    (awk '/P-value for each locus pair/ {exit} 
          NF==0 {next;} 
          /-------/ {next;} 
          /Locus\#1/ && /Switches/ {print "Pop Locus1 Locus2 Pvalue StdErr Switches"; go=1; next} 
          /information/ || /contingency/ {print $1,$2,$3,"NA NA NA"; next} 
          go==1 {print $1,$2,$3,$4,$5,$6} ' $F > $OUTD/LD_flatfile_genepop.txt) && echo "Summarized HWE results in $F into  $OUTD/LD_flatfile_genepop.txt";  

    # then get the proportion of significant tests for each population
    ((echo Pop; cat the_pops.txt) > $OUTD/LD_perc_signif_tests.txt;
    for C in .001 .01 .025 .05 .1; do
	(cat $OUTD/LD_flatfile_genepop.txt; echo "xxxxxxxxxxxxxxxxxx"; cat the_pops.txt) | \
	    awk -v c=$C  'BEGIN {printf("LD.at%s\n",c);} /xxxxxxxxxxx/ {go=1; next} NR>1 && go==0 { if($4<c) x[$1]+=1.0; n[$1]+=1.0;} go==1 {if($1 in n) printf("%.1f\n",100.0*x[$1]/n[$1]); else printf("NA\n");}' | \
	    paste $OUTD/LD_perc_signif_tests.txt - >> temp;
	mv temp $OUTD/LD_perc_signif_tests.txt;
    done;) && echo "Summarized LD results into $OUTD/LD_perc_signif_tests.txt"

else
    echo "No File $F so no LD summaries";
fi





F=gsisim/MissingDataTable.txt
if [ -f $F ]; then 

    # first summarize average number of typed loci by pop
     (awk -F"\t" 'BEGIN {printf("Pop\tAve.Num.Typed.Loci\n");} 
                  NR==1 {nl=NF-3; next} 
                  NR==2 {next} 
                  {printf("%s\t%.1f\n", $1,(1.0-$3)*nl)}' $F > $OUTD/AverageNumLociTypedPerPop.txt ) && echo "Summarized average number of loci typed per population into $OUTD/AverageNumLociTypedPerPop.txt ";

     # then summarize missing data rate by locus
     (awk -F"\t"  '
        BEGIN {printf("Locus\tFract.Missing\n")} 
        NR==1 {for(i=4;i<=NF;i++) lname[i]=$i; next} 
        $1=="ALL_POPS" {for(i=4;i<=NF;i++) printf("%s\t%s\n",lname[i],$i); exit; }' $F > $OUTD/MissingDataRateByLocus.txt ) && echo "Summarized missing data rate by locus into $OUTD/MissingDataRateByLocus.txt"

else
    echo "No File $F so no summaries of amount of successful versus missing genotyping";
fi





F=fstat/genos_fstat.out
if [ -f $F ]; then 

    # first summarize average number of alleles by pop
     ( (awk 'NF>0 {print "POPNAMES:",$1}' the_pops.txt; cat $F) |  awk '
       BEGIN {printf("Pop\tAve.Num.Alleles\n");}
       $1=="POPNAMES:" {pname[++n]=$2;} 
       /number of alleles sampled/ {go=1; next} 
       NF==0 || /\*\*\*\*\*\*\*\*\*\*\*\*\*/ {go=0; next} 
       go==1 && /[a-zA-Z0-9]/ {m+=1.0; for(i=2;i<=NF;i++) sum[i]+=$i;  } 
       END {for(i=1;i<=n;i++) printf("%s\t%.2f\n",pname[i],sum[i+1]/m);}' > $OUTD/AveNumAllelesByPop.txt ) && echo "Summarized average number of alleles across loci in each population into $OUTD/AveNumAllelesByPop.txt  ";

     # then summarize the average allelic richness by pop
     ( (awk 'NF>0 {print "POPNAMES:",$1}' the_pops.txt; cat $F) |  awk '
       $1=="POPNAMES:" {pname[++n]=$2;} 
       /based on min. sample size of:/ {go=1; minsamp=$7; ploidy=$8;
          printf("Pop\tAve.Num.Alleles.From%d.%s.Indivs\n",minsamp,ploidy); next} 
       NF==0 || /\*\*\*\*\*\*\*\*\*\*\*\*\*/ {go=0; next} 
       go==1 && /[a-zA-Z0-9]/ {m+=1.0; for(i=2;i<=NF;i++) sum[i]+=$i;  } 
       END {for(i=1;i<=n;i++) printf("%s\t%.2f\n",pname[i],sum[i+1]/m);}' > $OUTD/AveAllelicRichnessByPop.txt ) && echo "Summarized average allelic richness in each population into $OUTD/AveAllelicRichnessByPop.txt   ";

else
    echo "No File $F so no summaries of average number of alleles or average allelic richness for each population. ";
fi






