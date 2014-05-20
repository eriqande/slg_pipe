# put default values here
# VAR=default



function usage {
      echo Syntax:
      echo "  $(basename $0)  Path-to-Structure-Outfiles "
      echo " 
Note that the files have be named the way they are by the pipeline
(i.e. StructOuput_*dat*)
"
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
if [ $# -ne 1 ]; then
    usage;
    exit 1;
fi


DIR=$1


# uncomment to process a series of remaining parameters in order
rm -f xxxSummary.temp
for i in $DIR/StructOuput_*_dat*; do
    j=$(basename $i)
    D=$(echo $j | sed 's/StructOuput_genos_slg_pipe.txt_dat//g; s/_k.*//g;')
    K=$(echo $j | sed 's/StructOuput_genos_slg_pipe.txt_dat[0-9]*_k//g; s/_.*//g;')
    R=$(echo $j | sed 's/StructOu.*_Rep//g; s/\.txt_f//g;')
    awk  -v r=$R -v k=$K -v d=$D '/Estimated Ln Prob of Data/ {lnpd=$NF}
 					/Mean value of ln likelihood/ {mll=$NF}
 					/Variance of ln likelihood/ {vll=$NF}
 					/Mean value of alpha/ {ma=$NF}
 					/Mean value of Fst/ {mvf[++f]=$NF}
					END {
						printf("%s\t%s\t%s\t%s\t%s\t%s\t%s", d, k, r, lnpd, mll, vll, ma)
						for(i=1;i<=f;i++) printf("\t%s",mvf[i]);
						printf("\n");
					}
			' $i >> xxxSummary.temp
done


# now we have to put the colum headers on
MAXCOL=$(awk '{if(NF>maxf) maxf=NF} END {print maxf}' xxxSummary.temp)

awk -v mc=$MAXCOL '
BEGIN {
	OFS="\t";
	printf("Dat\tK\tRep\tLN.P.D\tMean.Log.Like\tVar.Log.Like\tMean.Alpha");
	for(i=i;i<=(mc-7); i++)  printf("\tFst.%d", i);
	printf("\n");
	} 
{
	printf("%s", $0); 
	for(i=(NF+1);i<=mc;i++) printf("\tNA"); 
	printf("\n");
} ' xxxSummary.temp 

rm xxxSummary.temp 



