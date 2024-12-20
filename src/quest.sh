#!/bin/bash

declare -A QUEST_ENV=(
    [default_cmd]='display_default_report'
    [config]="$QUESTRC"
    [data]="$QUESTDATA"
    [mode]='SELECT' # SELECT, INSERT, UPDATE, DELETE, EXECUTE
)

# I named this pattern CFOP: command (vita) / filter / operation / parameters
declare -A QUEST_ARG=(
    # these will determine the mode of execution
    [insert]=0
    [modify]=0
    [delete]=0
    [execute]=0
    # 
    [filter]=''
    [operands]=''
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
    export TASKRC="${QUEST_ENV[config]}"
    export TASKDATA="${QUEST_ENV[data]}"
    # TODO: check if QUESTRC and QUESTDATA exits AND are valid
}

quest_parse() {
    
    # Iterate over arguments using a while loop, what actions can quest do?
    while [[ $# -gt 0 ]]; do

        # is argument a special operator?...
        case "$1" in
            --select)
                # This is the default mode, but maybe it could help by preventing arguments to
                # be interpretted as special keywords?
                ;;
            --execute | ex | -x | /)
                QUEST_ENV[mode]='EXECUTE'
                QUEST_ARG[execute]=1
                ;;
            --insert | new | add | -a | -i)
                QUEST_ENV[mode]='INSERT'
                QUEST_ARG[insert]=1
                ;;
            --modify | mod | -u | -m)
                QUEST_ENV[mode]='UPDATE'
                QUEST_ARG[modify]=1
                ;;
            --delete | delete | del | -d | rm)
                QUEST_ENV[mode]='DELETE'
                QUEST_ARG[delete]=1
                ;;
            *)
                QUEST_ARG[filter]+=" $1"
                ;;
        esac

        # ...if yes, stop further processing, consider remaining args as operands
        if [[ "${QUEST_ENV[mode]}" != 'SELECT' ]]; then
            shift                      # discard current argument
            QUEST_ARG[operands]="$@"   # pass all remaining args to operator
            break                      # terminate loop
        else
            shift
        fi

    done
}

quest_validate() {
    :
}

quest_dispatch() {
    mode="${QUEST_ENV[mode]}"
    filter="${QUEST_ARG[filter]}"
    operands="${QUEST_ARG[operands]}"
    run_default_command="${QUEST_ENV[default_cmd]}"
    
    # report errors if any
    report_error

    # execute action based on input
    case "$mode" in
        EXECUTE) do_execute $operands ;;
        SELECT) do_select $filter ;;
        INSERT) do_insert $operands ;;
        UPDATE) do_update "$filter" "$operands" ;;
        DELETE) do_delete "$filter" "$operands" ;;
    esac
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

display_default_report() {
    task
}

# grep_column() { # $1=column $2=search term $3=optional_report
    # just use the uda.has: syntax
    # ids=$(task "$3" export | jq -r ".[] | select(.\"$1\" != null) | \"\(.id) \(.\"$1\")\"" | grep -F "$2" | awk '{print $1}')
    # task $ids
# }

do_select() {
    task $@
}

do_insert(){
    if [[ -z "$@" ]]; then
        launch_empty_form
    else
        shift ; task add "$@"
    fi
    return $?
}

launch_empty_form() {
    task add '-'
    last_insert_id=$(task export last_insert | jq '.[].id')
    task edit $last_insert_id
}

do_update() {
    if [[ -z "$1$2" ]]; then
        echo "Modify which?"
    elif [[ -z "$2" ]]; then
        task $1 edit
    elif [[ -z "$1" ]]; then
        task $2 edit
    else
        task $1 mod $2
    fi
    return $?
}

do_delete() {
    if [[ -z "$1$2" ]]; then
        echo "Delete which?"
    else
        task $1 delete $2
    fi
    return $?
}

do_execute() {
    task $@
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
