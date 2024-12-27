#!/bin/bash

declare -A CV_ENV=(
    [default_cmd]='display_default_report'
    [config]="$CVRC"
    [data]="$CVDIR"
    [mode]='NORMAL' # NORMAL, SELECT, RENDER, INSERT, VIEW, QUERY
)

declare -A CV_ARG=(
    [list]=0
    [render]=0
    [insert]=0
    [view]=0
    [path]=0
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
    
    # Iterate over arguments using a while loop, if operator set then...
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
            view | open | -v)
                CV_ARG[view]=1
                CV_ENV[mode]='VIEW'
                operator_set=yes
                ;;
            insert | create | add | new)
                CV_ARG[insert]=1
                CV_ENV[mode]='INSERT'
                operator_set=yes
                ;;
            --get-path | path | -p)
                CV_ARG[path]=1
                CV_ENV[mode]='QUERY'
                operator_set=yes
                ;;
            *)
                CV_ARG[operands]+=" $1"
                ;;
        esac

        # ...if operator set then stop further processing, consider remaining args as operands
        if [[ -n "$operator_set" ]]; then
            shift                      # discard current argument
            CV_ARG[operands]+=" $@"    # pass all remaining args to operator
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
    view=${CV_ARG[view]}
    get_path=${CV_ARG[path]}
    param="${CV_ARG[operands]}"

    is_true $list     && list_resumes
    is_true $render   && render_resume $param
    is_true $insert   && insert_resume $param
    is_true $view     && view_resume $param
    is_true $get_path && get_path $param
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

view_resume() {
    dir="${ENV[data]}/cv"
    for id in $@; do
        uuid=$(get_uuid $id)
        file="$dir/$uuid/cv.pdf"
        if [[ -z "$uuid" ]]; then
            echo "No UUID found for cv #$id"
        elif [[ ! -f "$file" ]]; then
            echo "$file does not exist!"
        else
            xdg-open "$file" &
        fi
    done
}

# gets the path to the pdf file represented by the uuid or the id of the cv
get_path() {
    dir="${ENV[data]}/cv"
    for id in $@; do
        uuid=$(get_uuid $id)
        file="$dir/$uuid/cv.pdf"
        if [[ -z "$uuid" ]]; then
            echo "No UUID found for cv #$id"
        elif [[ ! -f "$file" ]]; then
            echo "$file does not exist!"
        else
            echo "$file"
        fi
    done
}

get_uuid() {
    long_uuid=$(task _get $id.uuid)
    echo ${long_uuid:0:8}
}

cv_main "$@"
