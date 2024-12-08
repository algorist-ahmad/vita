#!/bin/bash

declare -A ENV=(
    [root]=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")") # path to project root
    [pwd]=$(pwd)
    [error]=0
    [noarg]=0
)

declare -A FILE=(
    [log]="$LOGS/vita.log"
    [help]="${ENV[root]}/doc/help.txt"
)

declare -A ERROR=(
    [0]='OK'
    [150]='ERROR 1: desc'
    [151]='ERROR 2: desc'
    [152]='ERROR 3: desc'
    [153]='ERROR 4: desc'
    [154]='ERROR 5: desc'
    [155]='ERROR 6: desc'
)

declare -A ARG=(
        [input]="$@"
        [debug]=0
        [help]=0
        [stat]=0
        [config]='null'       # show, key:value
        [job]='null'          # list, add, del, show, edit
        [cv]='null'           # list, add, del, show, edit, clone, query, render
        [template]='null'     # list, add, del, show, edit
        [doc]='null'          # list, add, del, show
        [render]='null'       # <resume-uuid> [--template <template-label>] [--output <file-path>]
        [link]='null'         # <job-id> <resume-uuid>
        [unknown]=''          # unknown args
    )

#########################################################

main() {
    initialize   # setup environment and check for missing files
    dissect "$@" # break input for analysis
    validate     # validate the operation
    dispatch     # execute the operation
    terminate    # execute post-script tasks regardless of operation
}

# prepare program for execution
initialize() {
    # if no arg provided, get help
    [[ -z "${ARG[input]}" ]] && ENV[noarg]=1 && ARG[help]=1
}

dissect() {

    local last_option='unknown'
    
    # Iterate over arguments using a while loop
    while [[ $# -gt 0 ]]; do
        case "$1" in

            debug | --debug)
                ARG[debug]=1 ;
                ;;
            help | --help | -h)
                ARG[help]=1 ;
                ;;
            stat)
                ARG[stat]=1 ;
                ;;               
            config)
                ARG[config]='' ;
                last_option='config' ;
                ;;
            job | -j)
                ARG[job]='' ;
                last_option='job' ;
                ;;
            cv | -c)
                ARG[cv]='' ;
                last_option='cv' ;
                ;;
            template | -t)
                ARG[template]='' ;
                last_option='template' ;
                ;;
            doc | -d)
                ARG[doc]='' ;
                last_option='doc' ;
                ;;
            render | -r)
                ARG[render]='' ;
                last_option='render' ;
                ;;
            link | -l)
                ARG[link]='' ;
                last_option='link' ;
                ;;
            --)
                last_option='unknown' ; # resets last option
                ;;
            *)
                ARG[$last_option]="${ARG[$last_option]} $1" ;
                ;;

        esac ; shift # discard argument
    done
}

validate() {
    :
    # check_for_error1
    # check_for_error2
    # ...
}

dispatch() {

    e="${ENV[error]}"
    
    if [[ $e -gt 0 ]]; then
        echo "Error: $(get_error_msg $e)" >&2
        exit $e
    fi

    [[ ${ARG[help]} -eq 1 ]] && print_help
    # [[ "${ARG[create]}" -eq 1 ]] && do_create
    # [[ "${ARG[edit]}"   -eq 1 ]] && do_edit
    # [[ "${ARG[delete]}" -eq 1 ]] && do_delete
    # [[ "${ARG[dir]}"    -eq 1 ]] && print_dir
    
    # ...else
    #     echo "Error: No valid operation specified." >&2
    #     exit 1
    # fi
}

terminate() {
    code=$?
    # if debug is true, reveal variables
    [[ ${ARG[debug]} -eq 1 ]] && reveal_variables
    exit $code
}

print_help() {
    bat $(get_file help)
}

# Loop through the keys of the associative array and print key-value pairs
reveal_variables() {
    local yellow="\033[33m"
    local green="\033[32m"
    local red="\033[31m"
    local purple="\033[35m"
    local reset="\033[0m"

    echo -e "--- ARGUMENTS ---"
    for key in "${!ARG[@]}"; do
        value="${ARG[$key]}"
        value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace
        value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
        color="$reset"

        if [[ $value == 'null' ]]; then
            color=$purple    # Null value
        elif [[ $value == '1' ]]; then
            color=$green     # True value
        elif [[ $value == '0' ]]; then
            color=$red       # False value
        fi

        printf "${yellow}%-20s${reset} : ${color}%s${reset}\n" "$key" "$value"
    done

    echo -e "--- ENVIRONMENT ---"
    for key in "${!ENV[@]}"; do
        value="${ENV[$key]}"
        value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace
        value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
        color="$reset"

        if [[ $value == 'null' ]]; then
            color=$purple    # Null value
        elif [[ $value == '1' ]]; then
            color=$green     # True value
        elif [[ $value == '0' ]]; then
            color=$red       # False value
        fi

        printf "${yellow}%-20s${reset} : ${color}%s${reset}\n" "$key" "$value"
    done

    echo -e "--- FILES ---"
    for key in "${!FILE[@]}"; do
        value="${FILE[$key]}"
        value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace
        value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
        color="$reset"

        if [[ $value == 'null' ]]; then
            color=$purple    # Null value
        elif [[ $value == '1' ]]; then
            color=$green     # True value
        elif [[ $value == '0' ]]; then
            color=$red       # False value
        fi

        printf "${yellow}%-20s${reset} : ${color}%s${reset}\n" "$key" "$value"
    done
}

# helpers

get_env() { echo "${ENV[$1]}"; }
get_file() { echo "${FILE[$1]}"; }
get_error_msg() { echo "${ERROR[$1]}"; }

# helpers

main "$@"
