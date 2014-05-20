
STEPS="  1. create a gendist input file.  Copy it to gendist_input.txt 
  2. run gendist with the CSE option on that file.  Copy the output to gendistORIG_outfile.txt
  3. run neighbor on that gendist output.  Copy the output to neighborORIG_outfile.txt
     and neighborORIG_outtree.txt
  4. run seqboot on the gendist file with NumBoot bootstrap replicates.  Copy
     the output to seqboot_outfile.txt
  5. run gendist with the CSE option on the seqboot output.  Copy the output to
     gendistBOOT_outfile.txt 
  6. run neighbor on that gendist output. Copy output to neighborBOOT_outfile.txt and
     neighborBOOT_outtree.txt
  7. run consense on neighborBOOT_outtree.txt. Copy output to consense_outfile.txt and
     consense_outtree.txt 
  8. Run eric's homebrew script for gathering bootstrap values for subtrees off the consensus 
     tree and transferring them in the comments field (i.e. [80]) in the consensus tree and 
     also the original tree with branch lengths.  The output for these are in the files:

          consense_tree_with_bootval_labels_XX.txt 
     and 
          original_tree_with_bootval_labels_XX.txt

     where XX is 0, 10, ... 90, 95 and denotes the percentage bootstrap support below which
     the labels do not appear on the tree.
"

 

if [ $# -ne 2 ]; then
    echo "Syntax:

    $(basename $0)   AlleFreqFile  NumBoot

The AlleFreqFile is the standard file of allele freqs in the slg_pipe format.
NumBoot is the number of bootstrap replicates (usually 100 or 1000).

This script automates a series of steps:
$STEPS 

Note that all these phylip programs and other scripts must be in your \$PATH

"
    exit 1;
fi



AF=$1;
BOOTS=$2;


# make the gendist input
(alle_freqs2gendist_intput.sh $AF > gendist_input.txt)  || \
!(echo "FATAL error! Could not run alle_freqs2gendist_intput.sh $AF > gendist_input.txt. Exiting..." >&2) || exit 1; 

# copy to an infile
cp gendist_input.txt infile

# run gendist and move output to permanent location
rm -f outfile;  
((echo A; echo C; echo Y) | gendist) || !(echo "FATAL error! Failed trying to run gendist on original data. Exiting..." >&2) || exit 1;
mv outfile gendistORIG_outfile.txt;


# run neighbor on that
(cp gendistORIG_outfile.txt infile) || !(echo "FATAL error! Could not copy  gendistORIG_outfile.txt to infile for neighbor. Exiting..." >&2) || exit 1;
rm -f outfile outtree; 
((echo J; echo $(( $(cl_rand -u 1 100000 10000000)*2 +1)); echo Y ) | neighbor) || \
 !(echo "FATAL error! Failed trying to run neighbor on original data. Exiting..." >&2) || exit 1;

mv outfile neighborORIG_outfile.txt;
mv outtree neighborORIG_outtree.txt



# run seqboot
(cp gendist_input.txt infile) || !(echo "FATAL error! Could not copy gendist_input.txt to infile for seqboot. Exiting..." >&2) || exit 1;
rm -f outfile outtree;
( (echo D; echo D; echo D; echo A; echo R; echo $BOOTS; echo Y;  echo $(( $(cl_rand -u 1 100000 10000000)*2 +1))) | seqboot) || \
 !(echo "FATAL error! Failed trying to run seqboot. Exiting..." >&2) || exit 1;
mv outfile seqboot_outfile.txt;


# now run gendist on the seqboot output
cp seqboot_outfile.txt infile
rm -f outfile;  
((echo A; echo C; echo M; echo $BOOTS; echo Y) | gendist) || \
!(echo "FATAL error! Failed trying to run gendist on the seqboot output. Exiting..." >&2) || exit 1;
mv outfile gendistBOOT_outfile.txt;



# now run neighbor on that gendist output
rm -rf outfile outtree;
cp gendistBOOT_outfile.txt infile;
((echo J;  echo $(( $(cl_rand -u 1 100000 10000000)*2 +1)); echo M; echo $BOOTS; echo $(( $(cl_rand -u 1 100000 10000000)*2 +1)); echo Y ) | neighbor) || \
!(echo "FATAL error! Failed trying to run neighbor on the seqboot output. Exiting..." >&2) || exit 1;
cp outfile neighborBOOT_outfile.txt;
cp outtree neighborBOOT_outtree.txt;


# and finally run consense on the neighbor output
rm -rf outfile outtree;
cp neighborBOOT_outtree.txt intree;
(echo Y | consense ) || \
!(echo "FATAL error! Failed trying to run consense on the neighbor output. Exiting..." >&2) || exit 1;
mv outfile consense_outfile.txt;
mv outtree consense_outtree.txt;


# and here we make trees that have the interior nodes labelled with bootstrap values:
cat consense_outtree.txt neighborORIG_outtree.txt > boot_val_transfer_input.txt
for BCUT in 0 10 20 30 40 50 60 70 80 90 95; do 
     boot_vals_onto_distance_tree.sh  boot_val_transfer_input.txt $BOOTS $BCUT;
     mv labelled_bootval_tree_1.txt consense_tree_with_bootval_labels_$BCUT.txt;
     mv labelled_bootval_tree_2.txt original_tree_with_bootval_labels_$BCUT.txt;
done





echo "Completed the Phylip Phase of the Standard Analysis

We did the following steps:
$STEPS

And now I am going to delete the following files, because they can be huge and 
can easily be regenerated:
     seqboot_outfile.txt 
     gendistBOOT_outfile.txt
     infile 
     neighborBOOT_outfile.txt 
     intree 
     neighborBOOT_outtree.txt

"

rm -f seqboot_outfile.txt gendistBOOT_outfile.txt infile neighborBOOT_outfile.txt intree neighborBOOT_outtree.txt;