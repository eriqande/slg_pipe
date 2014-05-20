# to see how this should be called, see the script Do_sibyanking.sh

# collect the random numbers on the first line
NR==1 {
    for(i=1;i<=NF;i++) rando[i]=$i;
    next;
}


# if you get to here, you have reached a new part of the input
/xxxxxxxxxxxxxxxx/ {
    go++;
    next;
 }



# while go==0 you collect the number of typed gene copies in each individual
go==0 {
    typed[$1]=$2;
}


# while go==1 you select individuals from each sibship as appropriate
go==1 {
    if(NF<=Cutoff+1) {  # there are two columns before you get to the indivs.  So, if anything < Cutoff is kept completely, then this is what you want. 
	for(i=3;i<=NF;i++) {
	    keep[$i]++;
	}
    }
    else {
	n=0; sum=0.0;
	for(i=3;i<=NF;i++) {  # get the ids and weights of each individual
	    id[n]=$i;
	    prob[n]=typed[$i]*1.00000000001; # do this extra bit to keep it from doing integer division later
	    sum+=prob[n];
	    n++;
	}
	for(i=0;i<n;i++) {
	    prob[i] /= sum;  
	}
	m++;
	the_rand = rando[m];  # get the random number to work with
	cumul=0.0;
	for(i=0;i<n;i++) {
	    cumul += prob[i];
	    if(cumul>the_rand) {
		keep[id[i]];
		next;
	    }
	}
	keep[id[n-1]];   # this is just in case it slipped through due to numerical instability
    }
}



# now, pick out the ones from the actual data set
go==2 {
    if($1 in keep) print;
}
