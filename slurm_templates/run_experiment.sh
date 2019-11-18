#!/usr/bin/env bash
# Author(s): James Owers (james.f.owers@gmail.com)

print_usage () {
  cat << EOM
Usage: $0 -t slurm_template -e experiment_textfile [-m max_nr_parallel_jobs] [sbatch_args]
  Convenience function for running arrayjob experiments with slurm. Expects
  the user to have created a bash script to supply to sbatch, and a text file
  with each line containing a command to run a single experiment. For a filled
  out example of a bash script to supply to sbatch, and an experiment file,
  see the directory ./example adjacent to this with its README.md. You can use
  slurm_arrayjob.sh.template adjacent to this script to help you create your
  own too.

Arguments:

  -t slurm_template : str
     the path to the bash script to supply to sbatch
     
  -e experiment_textfile : str
     a file which contains a command to run on each line
     
  -m (optional) max_nr_parallel_jobs : int
     the maximum number of jobs that can run simultaneously. If not
     not specified, defaults to 10
     
  all remaining args (optional) sbatch_arg : str
     all remaining arguments will be combined and supplied to the sbatch
     command being executed. N.B. you *must* specify max_nr_parallel_jobs
     to use this feature
    
Example call:
  $ run_experiment.sh -t example/slurm_arrayjob.sh -e example/experiments.txt -m 12 --gres=gpu:1 --mem=8000

EOM
}

BASH_SCRIPT=""
EXPT_FILE=""
MAX_PARALLEL_JOBS=10

# Parse args
while getopts 't:e:m:' flag; do
  case "${flag}" in
    t) BASH_SCRIPT="${OPTARG}" ;;
    e) EXPT_FILE="${OPTARG}" ;;
    m) MAX_PARALLEL_JOBS="${OPTARG}" ;;
    *) print_usage
       exit ;;
  esac
done

# Set all remaining args to SBATCH_ARGS (supplied direct to sbatch)
shift $((OPTIND -1))
SBATCH_ARGS="${@}"

# Check a bash script supplied
if [ -z "${BASH_SCRIPT}" ]; then
  echo "You give a bash script to supply to the sbatch command."
  echo "${#@}"
  print_usage
  exit 1
fi

# Check bash script exists
if [ ! -f "$BASH_SCRIPT" ]; then
  echo "${BASH_SCRIPT} does not exist"
  echo "${#@}"
  print_usage
  exit 1
fi

# Check an experiment file supplied
if [ -z "${EXPT_FILE}" ]; then
  echo "You give a file of experiment commands to run (supplied to bash script)."
  echo "${#@}"
  print_usage
  exit 1
fi

# Check experiment file exists
if [ ! -f "$EXPT_FILE" ]; then
  echo "${EXPT_FILE} does not exist"
  echo "${#@}"
  print_usage
  exit 1
fi

# Check/set maximum number of parallel jobs to run
re='^[0-9]+$'
if ! [[ $MAX_PARALLEL_JOBS =~ $re ]] ; then
  echo "The second argument is the max nr of parallel jobs"
  echo "It must be a number, you supplied ${MAX_PARALLEL_JOBS}"
  echo "${#@}"
  print_usage
  exit 1
fi

# Set the value for sbatch's --array argument
NR_EXPTS=`cat ${EXPT_FILE} | wc -l`
echo "Executing command: "\
   "sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS}"\
        "$SBATCH_ARGS $BASH_SCRIPT $EXPT_FILE"

# Run the sbatch command
sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS} $SBATCH_ARGS $BASH_SCRIPT $EXPT_FILE
