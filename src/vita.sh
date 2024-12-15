#!/bin/bash

declare -A ENV=(
    [root]=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")") # path to project root
    [config]="${VITARC:-$HOME/.vitarc}"                                 # 
    [data]="${VITADATA:-$HOME/.vita}"
    [message]='' # post-execution messages and warnings go here
    [pwd]=$(pwd)
    [error]=0
    [argless]=0
)

declare -A FILE=(
    [log]="$LOGS/vita.log"
    [help]="${ENV[root]}/aux/help.txt"
    [form]="${ENV[root]}/aux/quest.form.yml"
)

declare -A ERROR=(
    [0]='OK'
    [150]='ERROR 150: no resume identifier'
    [151]='ERROR 151: no such resume'
    [152]='ERROR 152: no cv.tex file'
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
        [quest]='null'        # list, add, del, show, edit
        [cv]='null'           # list, add, del, show, edit, clone, query, render
        [template]='null'     # list, add, del, show, edit
        [doc]='null'          # list, add, del, show
        [render]='null'       # <resume-uuid> [--template <template-label>] [--output <file-path>]
        [link]='null'         # <job-id> <resume-uuid>
        [unknown]='null'      # unknown args
    )

#########################################################

main() {
    initialize   # setup environment and check for missing files
    parse "$@"   # break input for analysis
    validate     # validate the operation
    dispatch     # execute the operation
    terminate    # execute post-script tasks regardless of operation
}

# prepare program for execution
initialize() {
    create_config_file
    create_data_directory
    handle_argless_run
}

parse() {

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
            quest* | qst | jobs | -q)
                ARG[quest]='' ;
                last_option='quest' ;
                ;;
            cv | resume | -c)
                ARG[cv]="" ;
                last_option='cv' ;
                ;;
            template* | tmpl | -t)
                ARG[template]='' ;
                last_option='template' ;
                ;;
            doc | -d)
                ARG[doc]='' ;
                last_option='doc' ;
                ;;
            --render)
                # [[ "$last_option" == 'cv' ]]
                ARG[render]='' ;
                last_option='render' ;
                ;;
            link | -l)
                ARG[link]='' ;
                last_option='link' ;
                ;;
            null)
                ENV[message]+='null has special meaning, rejected\n' ;
                ;;
            --)
                last_option='unknown' ; # resets last option
                ;;
            *)
                # if last option is unknown clear ARG[unknown]
                [[ "$last_option" == 'unknown' ]] && is_null "${ARG[unknown]}" && ARG[unknown]=''
                # last option specified captures the argument
                ARG[$last_option]="${ARG[$last_option]} $1" ;
                ;;

        esac ; shift # discard argument
    done
}

# makes sure no contradicting operation is ordered
validate() {
    :
}

dispatch() {

    e="${ENV[error]}"
    root="${ENV[root]}"
    cv="$root/src/cv.sh"
    quest="$root/src/quest.sh"
    template="$root/src/template.sh"
    
    # if an error is detected, output to stderr immediately
    if [[ $e -gt 0 ]]; then
        echo "Error: $(get_error_msg $e)" >&2
        exit $e
    fi

    is_true ${ARG[help]} && print_help
    is_true "${ARG[stat]}" && echo "stat: nothing happened"
    ! is_null "${ARG[cv]}" && source $cv ${ARG[cv]} # removed quotes because of leading whitespace
    ! is_null "${ARG[quest]}" && source $quest ${ARG[quest]}
    ! is_null "${ARG[template]}" && source $template ${ARG[template]}
    ! is_null "${ARG[doc]}" && echo "doc: nothing happened"
    ! is_null "${ARG[config]}" && echo "config file: ${ENV[config]}"
    ! is_null "${ARG[render]}" && echo "render: nothing happened"
}

terminate() {

    final_message="${ENV[message]}"
    unknown_args="${ARG[unknown]}"
    error_number=${ENV[error]}
    error_msg="${ERROR[$error_number]}"

    # warn of unknown arguments
    ! is_null "$unknown_args" && final_message+="Unknown arguments: $unknown_args\n"

    # if debug is true, reveal variables
    is_true ${ARG[debug]} && reveal_variables

    # if there are any errors, print
    [[ $error_number -gt 0 ]] && echo -e "$error_msg"

    # if there are any final messages, print
    [[ -n "$final_message" ]] && echo -e "\n$final_message"

    exit $error_number
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
    local cyan="\033[36m"
    local reset="\033[0m"

    echo -e "--- ARGUMENTS ---"
    for key in "${!ARG[@]}"; do
        value="${ARG[$key]}"
        value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace
        value="${value#"${value%%[![:space:]]*}"}"  # Trim leading whitespace
        color="$reset"

        if [[ $value == 'null' ]]; then
            value=""  # Null value
        elif [[ -z $value ]]; then
            value="EMPTY"  # Empty string
            color=$cyan    # Empty value
        elif [[ $value == '1' ]]; then
            color=$green   # True value
        elif [[ $value == '0' ]]; then
            color=$red     # False value
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
            value=""  # Null value
        elif [[ -z $value ]]; then
            value="EMPTY"  # Empty string
            color=$cyan    # Empty value
        elif [[ $value == '1' ]]; then
            color=$green   # True value
        elif [[ $value == '0' ]]; then
            color=$red     # False value
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
            value=""  # Null value
        elif [[ -z $value ]]; then
            value="EMPTY"  # Empty string
            color=$cyan    # Empty value
        elif [[ $value == '1' ]]; then
            color=$green   # True value
        elif [[ $value == '0' ]]; then
            color=$red     # False value
        fi

        printf "${yellow}%-20s${reset} : ${color}%s${reset}\n" "$key" "$value"
    done
}

create_config_file() {
    file="${ENV[config]}"
    if [[ ! -f $file ]]; then
        echo '# created by vita' > $file
        ENV[message]+="No config file found, created one at $file\n"
    fi
}

create_data_directory() {
    dir="${ENV[data]}"
    if [[ ! -d $dir ]]; then
        mkdir -p $dir
        ENV[message]+="No data directory found, create one at $dir\n"
    fi
}

handle_argless_run() {
    # if no arg provided, get help
    if [[ -z "${ARG[input]}" ]]; then
        ENV[argless]=1
        #ARG[help]=1
        echo -e "
    Commands:
        help          Display help information for commands and subcommands.
        quest         Manage job offers and applications.
        cv            Manage resumes (including the master CV) and filtered YAML resumes.
        render        Render a YAML resume to PDF.
        template      Manage resume templates.
        doc           Manage supporting documents.
        config        Manage global settings and preferences.
        stats         Display statistics about job applications, resumes, and templates.
        "
    fi
}

# helpers

set_env() { echo "${ENV[$1]}"; }
get_file() { echo "${FILE[$1]}"; }
get_error_msg() { echo "${ERROR[$1]}"; }
is_null() { [[ "$1" ==  'null' ]] }
is_true() { [[ "$1" -eq 1      ]] }
# is_null() { [[ "$1" == 'null' ]] && return 0 || return 1 ; } # deprecated
# is_true() { [[ "$1" -eq 1 ]] && return 0 || return  1 ; } # deprecated

# helpers

main "$@"
