#!/bin/bash

declare -A CV_ARG=(
    [list]=0
    [add]='null'
    [del]='null'
    [show]='null'
    [edit]='null'
    [clone]='null'
    [query]='null'
    [render]='null'       # <resume-uuid> [--template <template-label>] [--output <file-path>]
    [link]='null'         # <job-id> <resume-uuid>
    [unknown]='null'      # unknown args
)

cv_main() {
    cv_initialize
    cv_parse "$@"
    cv_validate 
    cv_dispatch
    cv_terminate
}

cv_initialize() {
    [[ -z "${ARG[cv]}" ]] && CV_ARG[list]=1
}

cv_parse() {

    local last_option='unknown' # lastop
    
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
            render | to-pdf | convert | -r)
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
                last_option='unknown' ; # resets last option, why tho idk
                ;;
            *)
                # if last option is unknown clear ARG[unknown] (remove the special string which identifies it as null)
                [[ "$last_option" == 'unknown' ]] && is_null "${CV_ARG[unknown]}" && CV_ARG[unknown]=''
                # last option specified captures the argument
                CV_ARG[$last_option]="${CV_ARG[$last_option]} $1" ;
                ;;

        esac ; shift # discard argument
    done
}

cv_validate() {
    :
}

cv_dispatch() {
    list=${CV_ARG[list]}
    render_id=${CV_ARG[render]}
    
    is_true $list && list_resumes
    ! is_null "$render_id" && render_resume $render_id
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

list_resumes() {
    cd "${ENV[data]}"
    tree cv -L 1
}

render_resume() {
    echo "rendering $1"
    #     pdflatex -output(?) OUTPUTDIR -draft(?) FILE > /dev/null
    # pdflatex -output(?) OUTPUTDIR FILE > /dev/null
}

cv_main "$@"
