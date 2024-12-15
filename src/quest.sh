#!/bin/bash

declare -A QUEST_ENV=(
    [default_cmd]='display_full_table'
    [config]="$QUESTRC"
    [data]="$QUESTDATA"
)

declare -A QUEST_ARG=(
    [input]="$@"
    [select]=1
    [add]='null'
    [modify]='null'
    [delete]='null'
    [execute]='null'
    [filter]=''
)

#########################################################

quest_main() {
    quest_initialize   # setup environment and check for missing files
    quest_parse "$@"   # break input for analysis
    quest_validate     # validate the operation
    quest_dispatch     # execute the operation
    quest_terminate    # execute post-script tasks regardless of operation
}

# prepare program for execution
quest_initialize() {
    :
    # TODO: check if QUESTRC and QUESTDATA exits AND are valid
}

quest_parse() {
    
    local last_option='filter'
    local option_locked= # latched onto last operation specified, cannot be changed once set
    local ignore= # for special keywords
    
    # Iterate over arguments using a while loop, what actions can quest do?
    while [[ $# -gt 0 ]]; do
        case "$1" in
            exe* | --execute | -x)
                # execute arguments by quest as is
                QUEST_ARG[execute]=''
                QUEST_ARG[select]=0
                [[ ! $option_locked ]] && option_locked=1 && last_option='execute'
                ignore=1
                ;;&
            add | --insert | --add | -a | -i)
                QUEST_ARG[add]=''
                QUEST_ARG[select]=0
                [[ ! $option_locked ]] && option_locked=1 && last_option='add'
                ignore=1
                ;;&
            mod* | --modify | -u | -m)
                QUEST_ARG[modify]=''
                QUEST_ARG[select]=0
                [[ ! $option_locked ]] && option_locked=1 && last_option='modify'
                ignore=1
                ;;&
            del* | --delete | -d)
                QUEST_ARG[delete]=''
                QUEST_ARG[select]=0
                [[ ! $option_locked ]] && option_locked=1 && last_option='delete'
                ignore=1
                ;;&
            *)
                # last option specified captures the argument
                if [[ $ignore -eq 0 ]]; then
                    QUEST_ARG[$last_option]="${QUEST_ARG[$last_option]} $1" ;
                else
                    ignore=0 ;
                fi
                ;;

        esac ; shift # discard argument
    done
}

quest_validate() {
    :
}

quest_dispatch() {

    TASKRC="${QUEST_ENV[config]}"
    TASKDATA="${QUEST_ENV[data]}"
    
    run_default_command="${QUEST_ENV[default_cmd]}"
    select="${QUEST_ARG[select]}"
    add_args="${QUEST_ARG[add]}"
    mod_args="${QUEST_ARG[modify]}"
    del_args="${QUEST_ARG[delete]}"
    exe_args="${QUEST_ARG[execute]}"
    filter="${QUEST_ARG[filter]}"
    
    # report errors if any
    report_error

    # execute action based on input
    if no_arg; then $run_default_command; return; fi
    is_true $select && quest_select "$filter"
    ! is_null "$add_args" && quest_insert "$add_args"
    ! is_null "$mod_args" && quest_modify "$filter" "$mod_args"
    ! is_null "$del_args" && quest_delete "$filter" "$del_args"
    ! is_null "$exe_args" && quest_execute "$exe_args"

}

quest_execute() {
  # for debugging
  QUEST_ARG[complete_command]="task $operation $@"
  # EXECUTE
  task $@
}

quest_terminate() {
    # Join CV_ARG into ARG with keys prefixed by "cv_"
    join_arrays QUEST_ARG ARG "quest_"
    join_arrays QUEST_ENV ENV "quest_"
    # return to parent (vita)
    return $error_number
}

display_full_table() {
    task
}

quest_select() {
    echo "quest select"
}

quest_insert(){
    echo "quest insert"
}

quest_modify() {
    echo "quest modify"
}

quest_delete() {
    echo "quest delete"
}

quest_execute() {
    echo "bypassing wrapper"
}

# helpers

    set_env() { echo "${ENV[$1]}"; }
    get_file() { echo "${FILE[$1]}"; }
    get_error_msg() { echo "${ERROR[$1]}"; }
    is_null() { [[ "$1" ==  'null' ]] }
    is_true() { [[ "$1" -eq 1      ]] }
    no_arg() { [[ -z "${QUEST_ARG[input]}" ]] }

    # if an error is detected, output to stderr immediately
    report_error() {
        e="${ENV[error]}"
        if [[ $e -gt 0 ]]; then
            echo "Error: $(get_error_msg $e)" >&2
            exit $e
        fi
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

# helpers

quest_main "$@"
