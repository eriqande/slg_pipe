
# this expects input with no line endings and no white spaces---just a series of semicolon delimited
# newick format trees.  The first one should be the consensus tree with the bootstrap values 
# in the branch lengths spot.  The bootstrap values should be a number between 0 and the number
# of bootstrap replicates.  It can have a decimal point (as phylip usually spits them out as such).

# This awk script is expecting input in the form of the number of bootstrap replicates 
# named NUMBOOT  and a cutoff which is the percent of bootstrap values below which 
# you don't want to label the nodes with.   For example:

#  awk -v NUMBOOT=1000  -v cutoff=80 -f subtree_grabber.awk

# will label only those subtrees found in 800 or more of the bootstrap 
# replicates.  It will label them as an integer which is the percentage
# of times the subtree was found  (i.e. 87 or 95, instead of 870 of 950
# or 870.0, etc.

# the output for each tree in the input goes into a file called 
#  labelled_bootval_tree_X.txt
# where X is the number of the tree.  X=1 should be the consensus tree
# and X>1 are the other ones.  Typically you will probably have 
# X no larger than 2, but you can do more if you want.



# A simple sort function from the sed and awk book
# it sorts an array A with N elements
function sort(A, N,    temp, i, j) {
    for(i=2;i<=N;++i) {
	for(j=i; (j-1) in A && A[j-1]>A[j]; --j) {
	    temp=A[j];
	    A[j]=A[j-1];
	    A[j-1]=temp;
	}
    }
    return;
}






BEGIN {RS=";"}  # make semicolon the record separator




# now, we just collect the subtrees from each line.  And if we are not in tree 1
# anymore then we insert the bootstrap values we got from tree 1
NF>0 {
    tree++;  # record the number of the tree;
    outtree[tree]=""; # initialize to accumulate a tree to spit out
    
    n=split($1,s,"");  # split the whole newick string into an array of n characters
    
    for(i=1;i<=length($1);i++) {  # cycle through the string
	
	# just copy this character over verbatim to the current outtree
	outtree[tree]=outtree[tree] s[i];
	
	# apparently awk has no "switch" conditional so just use ifs
	if(s[i]=="("  )  {
	    d++;  # d is the depth.  After incrementing, we want to move to the next character
	    grsub[d]="";  # initialize the growing subtree at this depth to empty
	}
	else {
	    if(match(s[i],/[a-zA-Z,]/)) { # here, if it matches an alpha character, we know it is part of a node name 
		# it also turns out that if it is a comma, we will just push that onto the growing subtrees
		# to delimit the leaves
		for(j=1;j<=d;j++) {  # cycle over the subtrees that are growing at different depths
		    grsub[j]=grsub[j] s[i];  # note that grsub will include only the names of these subtrees
		}
	    }
	    if(s[i]==")") {  # a right paren means that we have completed subtree at depth d so we
		# need to close that subtree out and name it and decrement d by 1
		n=split(grsub[d--],a,/,/); # make an array a by splitting grsub[d] on the commas;
		sort(a,n);
		name=a[1]; # initialize to get the name of the subtree
		for(j=2;j<=n;j++) name=name "," a[j];  # make a single string name for the subtree.  This will be part of a hash key
		
		# now, collect the branch lengths (which are the bootstrap values if tree==1)
		# while we are doing this we will be incrementing i, so we want to make sure that
		# we copy that stuff across to the outtree as well.
		branchlen="";
		if(s[i+1]==":")  {
		    outtree[tree]=outtree[tree] s[++i];
		    while(match(s[++i],/[0-9.]/))  {  # as long as we are still eating a number, append its digits branchlen and outtree
			branchlen=branchlen s[i];
			outtree[tree]=outtree[tree] s[i];
		    }
		    # decrement i by one so that the next time through it is starting up on that non-numeric character
		    --i;
		}
	  
		subtree_lengths[tree,name] = branchlen;

		# now, if that subtree appeared in the consensus tree, AND we aren't at the last parentheses, AND 
		# the percentage bootstrap value is greater than cutoff, then put the bootstrap value onto the outtree
		if( (1,name) in subtree_lengths && i<length($1)  && (100*subtree_lengths[1,name]/NUMBOOT)>=cutoff  ) outtree[tree]=sprintf("%s[%d]",outtree[tree], 100*subtree_lengths[1,name]/NUMBOOT);
		#print name,subtree_lengths[tree,name];
	    }	 
	}
    }
    # after all that, print the outtree for all the trees
    print outtree[tree] > sprintf("labelled_bootval_tree_%d.txt",tree);;
}

