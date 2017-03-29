#!/bin/bash

_cluster_jobs()
{
    local cur prev base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local job_ids=$(qstat -r | grep '^\W*[0-9][0-9]*\|Full jobname' | awk '{if ($1=="Full") {print $3} else {print $1}}')
    job_ids="${job_ids} help"
    COMPREPLY=( $(compgen -W "${job_ids}" -- ${cur}) )
    return 0
}

complete -F _cluster_jobs qtail qhead qcat qless
