

if [ $# -ne 2 ]; then
    echo "Syntax"
    echo "  $(basename $0)  DistructPS-File  Prefix "
    echo 
    echo "This produces an EPS with tight bounding box that is named
Prefix_DistructPS-File.eps.  It then makes a PDF file from that ESP.
This requires epstool and epstopdf.

Note that the input file should have a .ps ending or things will get weird and
could overwrite files!

This used to use epstool, but that is not really available as far as I can tell
so it just uses gs directly.
"
    echo
    exit 1;
fi

INPUT=$1
PREFIX=$2

BASE=$(basename $INPUT);

# get the extent of the file recorded as a bounding box. Note that gs seems to 
# return that to stderr.  Sort of inconvenient. It is sort of silly to 
# run gs twice, but that is what we are doing here
BBOX=$(gs  -dNOPAUSE -dBATCH -sDEVICE=bbox $INPUT  2>&1 | awk '/^%%Bound/' )
HRBB=$(gs  -dNOPAUSE -dBATCH -sDEVICE=bbox $INPUT  2>&1 | awk '/^%%HiRes/' )


# now, put that bounding box information in right after the PS header in the 
# original distruct file:
awk -v bb="$BBOX" -v hr="$HRBB"  '/^%!PS/ {print $0; print bb; print hr} {print}' $INPUT > ${PREFIX}_${BASE/.ps/.eps}

# make a pdf out of it:
./bin/epstopdf ${PREFIX}_${BASE/.ps/.eps}

