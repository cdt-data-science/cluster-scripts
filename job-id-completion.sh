#!/bin/bash

# Adds autocomplete to the scancel command.
# Typing "scancel <tab>" will give a list of your currently queued/running jobs.
# The job ID will be autocompleted if there is only a single job ID that matches
# what has been typed already.

_cluster_jobs()
{
    # Based on tutorial at:
    # https://iridakos.com/tutorials/2018/03/01/bash-programmable-completion-tutorial.html

    local cur prev base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # redefine field separator to preserve whitespace
    local IFS=$'\n'
   
    # Get Job numbers and names
    local job_ids=$(squeue --user ${USER} -o "%A (%j)" --noheader)

    # Filter based on what user hasd typed
    local suggestions=( $(compgen -W "${job_ids}" -- ${cur}) )

    if [ "${#suggestions[@]}" == "1" ]; then
        # if there's only one match, we remove the command literal
        # to proceed with the automatic completion of the number
        local number=$(echo ${suggestions[0]/%\ */})
        COMPREPLY=("$number")
    else
        # more than one suggestions resolved,
        # respond with the suggestions intact
        COMPREPLY=("${suggestions[@]}")
    fi

    return 0
}

complete -F _cluster_jobs scancel
