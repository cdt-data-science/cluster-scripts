#!/bin/bash
# Author(s): James Owers (james.f.owers@gmail.com)
# Last updated: Nov 2019

print_usage () {
  cat << EOM
  
Usage: 
  $0 -t path/to/slurm_arrayjob.sh -e path/to/experiment.txt \\
      [-m max_nr_parallel_jobs] [sbatch_args]

  Convenience function for running arrayjob experiments with slurm. Expects
  the user to have created a bash script to supply to sbatch, and a text file
  with each line containing a command to run a single experiment. For a filled
  out example of a bash script to supply to sbatch, and an experiment file,
  see the directory ./example adjacent to this with its README.md. You can use
  slurm_arrayjob.sh.template adjacent to this script to help you create your
  own too.

Arguments:

  -t path/to/slurm_arrayjob.sh : str
     the path to the bash script to supply to sbatch. This script contains the
     configuration for the sbatch arrayjob and takes experiment.txt as an 
     argument. It uses the slurm variable $SLURM_ARRAY_TASK_ID to select a line
     from experiment.txt and run it.
     
  -e /path/to/experiment.txt : str
     the path to the file which contains a command to run on each line. This is
     supplied to the bash script slurm_arrayjob.sh
     
  -m (optional) max_nr_parallel_jobs : int
     the maximum number of jobs that can run simultaneously. If not
     not specified, defaults to 10
     
  all remaining args (optional) sbatch_arg : str
     all remaining arguments will be combined and supplied to the sbatch
     command being executed. These arguments will override sbatch arguments you
     specified in slurm_arrayjob.sh
    
Example call:
  $ run_experiment.sh -t example/slurm_arrayjob.sh -e example/experiments.txt \\
      -m 12 --cpus-per-task=4 --gres=gpu:1 --mem=8000

  If example/experiments.txt contains 1000 lines, this would result in the
  following command being run:
  
  sbatch --array=1-1000%12 --cpus-per-task=4 --gres=gpu:1 --mem=8000 \\
      example/slurm_arrayjob.sh example/experiments.txt
  
EOM
}

BASH_SCRIPT=""
EXPT_FILE=""
MAX_PARALLEL_JOBS=10

# Parse args
while getopts 't:e:m:h' flag; do
  case "${flag}" in
    t) BASH_SCRIPT="${OPTARG}" ;;
    e) EXPT_FILE="${OPTARG}" ;;
    m) MAX_PARALLEL_JOBS="${OPTARG}" ;;
    h) print_usage
       exit ;;
  esac
done

# Set all remaining args to SBATCH_ARGS (supplied direct to sbatch)
shift $((OPTIND -1))
SBATCH_ARGS="${@}"

# Check a bash script supplied
if [ -z "${BASH_SCRIPT}" ]; then
  echo "You must give a bash script to supply to the sbatch command."
  print_usage
  exit 1
fi

# Check bash script exists
if [ ! -f "$BASH_SCRIPT" ]; then
  echo "${BASH_SCRIPT} does not exist"
  print_usage
  exit 1
fi

# Check an experiment file supplied
if [ -z "${EXPT_FILE}" ]; then
  echo "You must give a file of experiment commands to run "\
       "(which is supplied to bash script)."
  print_usage
  exit 1
fi

# Check experiment file exists
if [ ! -f "$EXPT_FILE" ]; then
  echo "${EXPT_FILE} does not exist"
  print_usage
  exit 1
fi

# Check/set maximum number of parallel jobs to run
re='^[0-9]+$'
if ! [[ $MAX_PARALLEL_JOBS =~ $re ]] ; then
  echo "The second argument is the max nr of parallel jobs"
  echo "It must be a number, you supplied ${MAX_PARALLEL_JOBS}"
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
