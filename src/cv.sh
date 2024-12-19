#!/bin/bash

declare -A CV_ENV=(
    [default_cmd]='display_default_report'
    [config]="$CVRC"
    [data]="$CVDIR"
    [mode]='NORMAL' # NORMAL, SELECT, RENDER, INSERT
)

declare -A CV_ARG=(
    [list]=0
    [render]=0
    [insert]=0
    [operands]=
)

cv_main() {
    cv_initialize
    cv_parse "$@"
    cv_dispatch
    cv_terminate
}

cv_initialize() {
    # [[ -z "${ARG[cv]}" ]] && CV_ARG[list]=1
    export TASKRC="${CV_ENV[config]}"
    export TASKDATA="${CV_ENV[data]}"
}

cv_parse() {

    operator_set=
    
    # Iterate over arguments using a while loop
    while [[ $# -gt 0 ]]; do
        case "$1" in
            list | -l)
                CV_ARG[list]=1
                CV_ENV[mode]='SELECT'
                operator_set=yes
                ;;
            render | to-pdf | convert | -r)
                CV_ARG[render]=1
                CV_ENV[mode]='RENDER'
                operator_set=yes
                ;;
            insert | create | add | new)
                CV_ARG[insert]=1
                CV_ENV[mode]='INSERT'
                operator_set=yes
                ;;
            *)
                CV_ARG[operands]+=" $1"
                ;;
        esac

        # ...if yes, stop further processing, consider remaining args as operands
        if [[ -n "$operator_set" ]]; then
            shift                      # discard current argument
            CV_ARG[operands]+="$@"     # pass all remaining args to operator
            break                      # terminate loop
        else
            shift
        fi

    done
}

cv_dispatch() {
    mode="${CV_ENV[mode]}"
    list=${CV_ARG[list]}
    render=${CV_ARG[render]}
    insert=${CV_ARG[insert]}
    param="${CV_ARG[operands]}"

    is_true $list && list_resumes
    is_true $render && render_resume $param
    is_true $insert && insert_resume $param
    if [[ "$mode" == 'NORMAL' ]]; then
        task $param
    fi
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

insert_resume() {
    if [[ -z "$@" ]]; then
        task add '.'
        last_insert_id=$(task export last_insert | jq '.[].id')
        task edit $last_insert_id
    else
        task add $@
    fi
}

# renders a .tex file
render_resume() {
    # begin init
        root="${ENV[root]}"
        id=$1
        dir="${ENV[data]}/cv" # relevant directory
        file="$dir/$id/cv.tex"
        rendered_file="$dir/$id/cv.pdf"
        loading_animation="${ENV[root]}/src/cool_loading_effect.sh"
    # end init

    # begin validation
        # id provided?
        [[ -z "$id" ]] && ENV[error]=150 && return 150
        # folder exists?
        [[ ! -d "$dir/$id" ]] && ENV[error]=151 && return 151
        # .tex file present?
        [[ ! -f "$file" ]] && ENV[error]=152 && return 152
        # .tex file valid?
        # im not doin that
    # end validation

    echo "Rendering..."
    $root/src/cool_loading_effect.sh

    # generate an aux file first to get an accurate count of total pages
    pdflatex -output-directory "$dir/$id" -draftmode "$file" > /dev/null
    # generate a pdf using the aux file generated earlier
    pdflatex -output-directory "$dir/$id" "$file" > /dev/null

    echo -e "PDF ready at $rendered_file"
    xdg-open "$rendered_file" 2>/dev/null
}

cv_main "$@"
