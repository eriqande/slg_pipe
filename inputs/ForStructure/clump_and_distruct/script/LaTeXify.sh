# set some defaults
DO_POPQ_ONLY=0;
DO_BOTH=0;
DO_POPQ=0;
DOUBLE_SLASH="\\\\\\\\"

function usage {
    echo Syntax:
    echo "$(basename $0) [-p] PathToPDFs  StringOfKs"
    echo "
PathToPDFs is just the directory (typically final_pdf)
where all the PDFs live.  It is best to leave the 
trailing slash off of it.

StringOfKs is a quoted string of the K-values that you want 
to get.

This script spits a LaTeX-able file out to stdout.  The
file stacks all the distruct plots for a single k on 
top of one another on a separate page.

If you give the -p flag, then it prints the PopQ plots
instead of the IndivQ plots in the output.

-s suppresses the double slashes at the end of each line that has
   a distruct plot on it.

-p Plots just the PopQ plots

-b Tells it to plot both the indiv-Q and the PopQ values

Example:

$(basename $0)  ./final_pdf  \"2 3 4 5\"

" 
}


if [ $# -eq 0 ]; then
    usage;
    exit 1;
fi;

# use getopts so you can pass it -n 50, for example. 
while getopts ":pbs" opt; do
    case $opt in
	p    )  DO_POPQ_ONLY=1;
	    ;;
	b    ) DO_BOTH=1
	    ;;
	s    )  DOUBLE_SLASH="";
	    ;;
	\?   )
	    usage
	    exit  1
	    ;;
    esac
done

shift $((OPTIND-1));





if [ $# -ne 2 ] ; then
   usage;
   exit 1; 
 
fi


DIR=$1
KS=$2


# first print the preamble
echo boing | awk '
{printf("\\documentclass[11pt]{article} \
\\usepackage{graphicx} \
\\usepackage{amssymb} \
\\usepackage{epstopdf} \
\\usepackage{amsfonts} \
\\usepackage{natbib} \
\\usepackage{subfigure} \
\\usepackage{pdfsync} \
\\usepackage{xspace} \
 \
\\textwidth = 6.5 in \
\\textheight = 9 in \
\\oddsidemargin = 0.0 in \
\\evensidemargin = 0.0 in \
\\topmargin = 0.0 in \
\\headheight = 0.0 in \
\\headsep = 0.0 in \
\\parskip = 0.2in \
\\parindent = 0.0in \
 \
 \
\\newlength{\\nameraise} \
\\setlength{\\nameraise}{.07in} \
 \
\\newlength{\\nameoverhang} \
\\setlength{\\nameoverhang}{.22in} \
 \
 \
\\begin{document} \
 \
");}
'

# now, choose how to do it
if [ $DO_BOTH -eq 1 ]; then
    CYCSTR="0 1"
elif [ $DO_POPQ_ONLY -eq 1 ]; then
    CYCSTR="1"
else 
    CYCSTR="0"
fi

# then cycle over the K-values
for k in $KS; do

    for DO_POPQ in $CYCSTR; do
	TOP=$DIR/BB_ds_Clumped_TopLabel_k`printf "%03d" $k`r001.pdf;
	if [ $DO_POPQ -eq 1 ]; then
	    TOP=$DIR/BB_ds_Clumped_PopQ_TopLabel_k`printf "%03d" $k`r001.pdf;
	fi
	SHORT=k`printf "%03d" $k`r001;
	echo $TOP $SHORT | awk -v ds=$DOUBLE_SLASH '{printf("\\includegraphics{%s}~\\hspace*{-\\nameoverhang}\\raisebox{\\nameraise}{%s} %s\n",$1,$2,ds);}';
	
	kstr=k`printf "%03d" $k`;
	zup=0;
	NOLABELS="$DIR/BB_ds_Clumped_NoLabel_${kstr}*";
	if [ $DO_POPQ -eq 1 ]; then
	    NOLABELS="$DIR/BB_ds_Clumped_PopQ_NoLabel_${kstr}*";
	fi
	for l in $NOLABELS; do
	    zup=$((zup+1));
	    if [ $zup -gt 1 ]; then
		echo $l ${kstr}r`printf "%03d" $zup` |  awk -v ds=$DOUBLE_SLASH '{printf("\\includegraphics{%s}~\\raisebox{\\nameraise}{%s} %s\n",$1,$2,ds);}';
	    fi;
	done;
    done;
    echo "Distruct Plots at \$K=$k\$."
    echo "\\newpage";
    echo; echo; echo;

#echo $k | awk '{printf("
done


echo "\\end{document}";
