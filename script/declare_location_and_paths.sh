# checks to make sure this is being executed in the arena (because
# it will generate paths assuming it is in there) and then 
# exports $PATH and also $SLG_PATH (which is the path 
# to the SCRIPTS directory)


# check to make sure that you are currently in "arena"
cwd=$(basename $(pwd));

if [ $cwd != "arena" ]; then
    echo "FATAL ERROR! You are not running $(basename $0) from within the \"arena\" directory" >&2;
    exit 1;
fi

# now get the full path to the directory above
slg_path="$(../bin/abspath ../)"


# then export PATH and SLG_PATH whether or not SLG_PATH is defined
export PATH=$slg_path/bin:$slg_path/script:$PATH;
export SLG_PATH=$slg_path;



