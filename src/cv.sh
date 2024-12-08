#!/bin/bash

declare -A CV_ARG=(
    [input]="$@"
    [list]=0
    [add]='null'
    [del]='null'
    [show]='null'
    [edit]='null'
    [clone]='null'
    [query]='null'
    [render]='null'       # <resume-uuid> [--template <template-label>] [--output <file-path>]
    [link]='null'         # <job-id> <resume-uuid>
    [unknown]=''          # unknown args
)

cv_main() {
    cv_initialize
    cv_parse "$@"
    cv_validate 
    cv_dispatch
    cv_terminate
}

cv_initialize() {
    [[ -z "${CV_ARG[input]}" ]] && CV_ARG[list]=1
}

cv_parse() {

    local last_option='unknown'
    
    # Iterate over arguments using a while loop
    while [[ $# -gt 0 ]]; do
        case "$1" in

            list | -l)
                CV_ARG[list]=1 ;
                last_option='list' ;
                ;;
            add | -a)
                CV_ARG[add]='' ;
                last_option='add' ;
                ;;
            del | rm)
                CV_ARG[del]='' ;
                last_option='del' ;
                ;;
            edit | mod | -e)
                CV_ARG[edit]='' ;
                last_option='edit' ;
                ;;
            clone | duplicate | -c)
                CV_ARG[clone]='' ;
                last_option='clone' ;
                ;;
            show | -s)
                CV_ARG[show]='' ;
                last_option='show' ;
                ;;
            query | get | -q)
                CV_ARG[query]='' ;
                last_option='query' ;
                ;;
            render | to-pdf | -r)
                CV_ARG[render]='' ;
                last_option='render' ;
                ;;
            link)
                CV_ARG[link]='' ;
                last_option='link' ;
                ;;
            null)
                ENV[message]+='null has special meaning, rejected\n' ;
                ;;
            --)
                last_option='unknown' ; # resets last option
                ;;
            *)
                CV_ARG[$last_option]="${CV_ARG[$last_option]} $1" ;
                ;;

        esac ; shift # discard argument
    done
}

cv_validate() {
    :
}

cv_dispatch() {
    is_true ${CV_ARG[list]} && list-cv
}

cv_terminate() {
    # Join CV_ARG into ARG with keys prefixed by "cv_"
    join_arrays CV_ARG ARG "cv_"
}

# Function to join arrays with prefixed keys
join_arrays() {
    local -n source_array=$1  # Source array to prefix and join
    local -n target_array=$2  # Target array to join into
    local prefix=$3           # Prefix to add to source array keys

    for key in "${!source_array[@]}"; do
        new_key="${prefix}${key}"  # Create prefixed key
        target_array["$new_key"]="${source_array[$key]}"  # Add to target array
    done
}

list-cv() {
    cd "${ENV[data]}"
    tree cv -L 1
}

cv_main "$@"
