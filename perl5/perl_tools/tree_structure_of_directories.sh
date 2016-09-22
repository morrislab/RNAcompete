#!/bin/bash 
# 
# dirtree - print directory tree 
# 
# Author:      Peter J. Acklam 
# Time-stamp:  2003-03-20 13:00:31 +0100 
# E-mail:      pjack...@online.no 
# URL:         http://home.online.no/~pjacklam 

########################################################################### #### 
# tree DIR [, PREFIX] 
# 
# This function does all the work, it scans a directory and then prints out the 
# files in each directory in a pretty format.  Note: It is recursive. 
# 
tree () { 
    local dir=$1 
    local prefix=$2 

    local fullsubdirs=$(ls -d "$dir"*/ 2>/dev/null) 
    if [[ -n $fullsubdirs ]]; then 
        local nsubdirs=$(printf '%s\n' "$fullsubdirs" | wc -l) 
        printf '%s\n' "$fullsubdirs" | while read fullsubdir; do 
            nsubdirs=$(( $nsubdirs - 1 ))       # number of subdirs left 
            fullsubdir=${fullsubdir%/}          # remove trailing / 
            local subdir=${fullsubdir#$dir}     # keep subdir name only 
            if [[ -L $fullsubdir ]]; then       # if a symlink 
                # 
                # Do not follow symlinks. 
                # 
                line=$(ls -l "$fullsubdir") 
                target=${line#* -> } 
                printf '%s+--%s -> %s\n' "$prefix" "$subdir" "$target" 
            elif [[ -r $fullsubdir && -x $fullsubdir ]]; then 
                # 
                # We must be able to enter a directory in order to tree it 
                # 
                printf '%s+--%s\n' "$prefix" "$subdir" 
                if (( $nsubdirs )); then 
                    tree "$fullsubdir/" "$prefix|  " 
                else 
                    tree "$fullsubdir/" "$prefix   " 
                fi 
            else 
                printf '%s+--%s (unreadable)\n' "$prefix" "$subdir" 
            fi 
        done 
    fi 

} 

########################################################################### #### 
# Process the list of directories.  Current directory is default. 
# 
if (( $# == 0 )); then 
    set -- . 
fi 
for dir; do 
    shift 

    if [[ ! -e $dir ]]; then 
        printf '%s: %s: no such file or directory\n' "$0" "$dir" >&2 
        continue 
    fi 

    if [[ ! -d $dir ]]; then 
        printf '%s: %s: not a directory\n' "$0" "$dir" >&2 
        continue 
    fi 

    ########################################################################### 
    # Clean up the path name, print the header, and print the directory tree. 
    # 
    dir=${dir%/} 
    if [[ $dir = '/' ]]; then 
        printf '%s\n' '/' 
    else 
        printf '%s\n' "$dir" 
    fi 
    tree "$dir/" 

    ########################################################################### 
    # Print some vertical space between each directory tree. 
    # 
    if (( $# )); then 
        printf '\n' 
    fi 

done 
