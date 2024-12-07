#!/bin/bash

declare -A ARGS=(
    [args]="$@"
    [debug]=0
)

declare -A FILES=(
    [data]="$SHEETS"
    [config_file]="$HOME/.config/my_script/config.yml"
    [log_dir]="$HOME/logs/"
)

declare -A FLAG=(
    [error]=0
)

declare -A ERROR=(
    [0]='OK'
    [11]="CONTRADICTING ARGUMENTS: select only 1 of the following: ls, new, edit, del"
)

#########################################################

main() {
    initialize   # setup environment and check for missing files
    dissect "$@" # break input for analysis
    validate     # validate the operation
    dispatch     # execute the operation
    terminate    # execute post-script tasks regardless of operation
}

initialize() {
    # echo "Setting up environment"
    # echo "Checking for missing variables or files"
    FLAG[error]=0
}

dissect() {

    LAST_OPTION=''
    
    # Iterate over arguments using a while loop
    while [[ $# -gt 0 ]]; do
        case "$1" in
            debug | --debug)
                NAMESPACE[debug]=1 ;
                ;;
            list | ls | '')
                NAMESPACE[select]=1 ;
                ;;                
            new | add | +*)
                NAMESPACE[create]=1 ;
                NAMESPACE[select]=0 ;
                ;;
            edit | open | mod)
                NAMESPACE[edit]=1 ;
                NAMESPACE[select]=0 ;
                ;;
            del* | rm | -*)
                NAMESPACE[delete]=1 ;
                NAMESPACE[select]=0 ;
                ;;
            dir)
                NAMESPACE[dir]=1 ;
                NAMESPACE[select]=0 ;
                ;;
            *)
                uuid_or_filename "$1" ;
                ;;
        esac
        # discard argument
        shift
    done
}

validate() {
    check_for_contradiction
    # check_for_error2
    # check_for_error3
    # ...
}

check_for_contradiction() {
    local count=0
    for key in select create edit delete; do
        if [[ "${NAMESPACE[$key]}" -eq 1 ]]; then
            ((count++))
        fi
    done

    if [[ $count -gt 1 ]]; then FLAG[error]=11; fi
}

dispatch() {

    if [[ "${FLAG[error]:-0}" -gt 0 ]]; then
        echo "Error: ${ERROR[${FLAG[error]}]}" >&2
        exit "${FLAG[error]}"
    fi

    [[ "${NAMESPACE[select]}" -eq 1 ]] && do_select
    [[ "${NAMESPACE[create]}" -eq 1 ]] && do_create
    [[ "${NAMESPACE[edit]}"   -eq 1 ]] && do_edit
    [[ "${NAMESPACE[delete]}" -eq 1 ]] && do_delete
    [[ "${NAMESPACE[dir]}"    -eq 1 ]] && print_dir
    
    # ...else
    #     echo "Error: No valid operation specified." >&2
    #     exit 1
    # fi
}

terminate() {
    reveal_variables
    help_if_no_arg
}

print_dir() {
    echo "${FILES[data]}" | xclip -selection clipboard
    echo "${FILES[data]}"
    echo "(copied)"
}

list_if_no_arg() {
     [[ "${NAMESPACE[args]}" == "" ]] && NAMESPACE[select]=1
}

help_if_no_arg() {
    [[ "${NAMESPACE[args]}" == "" ]] && echo 'Usage: sheet [new | mod | del] [UUID | FILENAME]' && exit 0
}

reveal_variables() {
    if [[ NAMESPACE['debug'] -eq 1 ]]; then
        # Loop through the keys of the associative array and print key-value pairs
        echo -e "\nDEBUG:"
        for key in "${!NAMESPACE[@]}"; do
            echo "Key: $key, Value: ${NAMESPACE[$key]}"
        done
    fi
}

uuid_or_filename() {
    echo "uuid or filename? $1"
}

do_select() {
    local uuids="${NAMESPACE[uuid]}"
    local names="${NAMESPACE[name]}"
    local select_all=$([[ -z "$uuids" && -z "$names" ]] && echo 'true' || echo 'false')

    if [[ $select_all == "true" ]]; then
        list_all_files
    else
        list_files_by_uuid $uuids
        list_files_by_name $names
    fi
}

list_all_files() {
    echo "listing all"
}

list_files_by_uuid() {
    echo "$@"
}

do_create() {
    echo "new spreadsheet!"
}

do_edit() {
    echo "opening in sc-im..."
}

do_delete() {
    echo "removing file..."
}

main "$@"
