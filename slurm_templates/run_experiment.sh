#!/usr/bin/env bash
# Author(s): James Owers (james.f.owers@gmail.com)

print_usage () {
  cat << EOM
Usage: $0 experiment_textfile [max_nr_parallel_jobs [sbatch_args]]
    Convenience function for running arrayjob experiments with slurm. Expects
    the user to have created a bash script slurm_arrayjob.sh which is on the
    path, and a text file with each line containing the command to run an
    experiment. See slurm_arrayjob.sh.template adjacent to this script and
    ./example/slurm_arrayjob.sh to help you create your own.

Arguments (all poisitional):
    1. experiment_textfile : str
        a file which contains a command to run on each line
    2. (optional) max_nr_parallel_jobs : int
        the maximum number of jobs that can run simultaneously. If not
        not specified, defaults to 10
    3. (optional) sbatch_arg : str
        all remaining arguments will be combined and supplied to the sbatch
        command being executed. N.B. you *must* specify max_nr_parallel_jobs
        to use this feature
        
Example call:
    $ run_experiment.sh example/experiments.txt 12 --partition=PGR-Standard --mem=8000

EOM
}

# Check slurm_arrayjob.sh on $PATH
if ! [ -x "$(command -v slurm_arrayjob.sh)" ]; then
    echo "You must create slurm_arrayjob.sh and add it to your PATH." >&2
    echo "${#@}"
    print_usage
    exit 1
fi

# Check an experiment file supplied
if [ ${#@} -lt 1 ]; then
    echo "You must supply a file of experiment commands to run."
    echo "${#@}"
    print_usage
    exit 1
fi

# Check experiment file exists
EXPT_FILE=$1
if [ ! -f "$EXPT_FILE" ]; then
    echo "${EXPT_FILE} does not exist"
    echo "${#@}"
    print_usage
    exit 1
fi

# Check/set maximum number of parallel jobs to run
if [ $# == 1 ]; then
    echo 'No max nr of parallel jobs provided, setting to 10'
    MAX_PARALLEL_JOBS=10 
else
    MAX_PARALLEL_JOBS=$2
    re='^[0-9]+$'
    if ! [[ $MAX_PARALLEL_JOBS =~ $re ]] ; then
        echo "The second argument is the max nr of parallel jobs"
        echo "It must be a number, you supplied ${MAX_PARALLEL_JOBS}"
        echo "${#@}"
        print_usage
        exit 1
    fi
fi

# Set the value for sbatch's --array argument
SBATCH_ARGS="${@:3}"
NR_EXPTS=`cat ${EXPT_FILE} | wc -l`
echo "Executing command: "\
     "sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS}"\
              "$SBATCH_ARGS slurm_arrayjob.sh $EXPT_FILE"

# Run the sbatch command
sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS} $SBATCH_ARGS slurm_arrayjob.sh $EXPT_FILE
