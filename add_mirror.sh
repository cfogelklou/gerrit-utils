#!/bin/bash
# Written by Chris Fogelklou
# Tested on Ubuntu 20 and MacOS bash

# Run this program from the top level directly, where "repo sync" is run.
top_path="$PWD"
echo "the path is $top_path"

if [ "$#" -ne 3 ]; then
    echo "Should be three parameters to this script"
    echo " add_mirror.sh <original repo root> <mirror repo root> <new repo name in each project>"
    echo " example:"
    echo "   bash add_mirror.sh ssh://my-origin-repo.reposerver.com:5555 ssh://me@192.168.0.1/git/mirror network"
    echo " or"
    echo "   bash add_mirror.sh ssh://my-origin-repo.reposerver.com:5555 /Volumes/SourceCode/localmirror_mirror local"
    exit 1
fi

# This is the server that will be "find/replaced" out to create a new repo for the project
old_repo_server=$1
new_repo_server=$2
new_repo_name=$3

#new_repo_server="/Volumes/SourceCode/local_mirror"
#new_repo_name="local"

# Create a file containing all remotes, then read into an array.
repo forall  -c 'echo `pwd` && git remote -v' > file.txt
IFS=$'\n' read -d '' -r -a lines < file.txt

# Read each line in the array
current_path=$top_path
for line in "${lines[@]}"
do
    # Some lines contain the current path
    if grep -q "$top_path" <<< "${line}"; then
        # This line is the current full path.
        echo "$line is the path"
        current_path=$line
    else
        # This line lists one of the repos for this project.
        echo "$line is not the path, but $current_path is"
        echo "Processing '$line'."

        # This is just here for debugging :-D
        set $line    # Extract the line into $1, $2, $3 etc.
        repo_name=$1
        repo_path=$2
        repo_type=$3

        # Only process when origin, push are specified (skip fetch)
        if [ "$repo_name" = "origin" ] && [ "$repo_type" = "(push)" ]; then
            echo "Processing '$repo_name'."
            # Print for debugging
            echo "  repo name: $repo_name"
            echo "  repo path: $repo_path"
            echo "  repo type: $repo_type"

            # Find/replace names. Use double quotes for variables, and | so paths are OK.
            new_repo=`echo ${repo_path} | sed "s|${old_repo_server}|${new_repo_server}|g"`

            pushd $current_path
            echo "**adding new repo name: $new_repo in $PWD"
            git remote add $new_repo_name $new_repo
            popd
        fi
    fi
done
