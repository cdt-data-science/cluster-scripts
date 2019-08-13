#!/usr/bin/env sh
## Template for use with a file containing a list of commands to run
## Example call:
##     sbatch slurm_template.sh python_script.py 10 'here' 'is' 'other' 'argzes'

#SBATCH -o /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -e /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -N 1	  # nodes requested
#SBATCH -n 1	  # tasks requested
#SBATCH --gres=gpu:1  # use 1 GPU
#SBATCH --mem=14000  # memory in Mb
#SBATCH -t 2:30:00  # time requested in hour:minute:seconds
#SBATCH --cpus-per-task=4  # number of cpus to use - there are 32 on each node.

############### Crap for logging ##################
source ~/.bashrc
set -e  # make script bail out after first error

# slurm info
echo "I'm running on ${SLURM_JOB_NODELIST}"

dt=$(date '+%d/%m/%Y %H:%M:%S');
echo $dt

# Set environment variables for input and output data
echo 'Setting experiment environment variables'
export STUDENT_ID=$(whoami)
export SCRATCH_HOME=/disk/scratch/${STUDENT_ID}
mkdir -p ${SCRATCH_HOME}  # making your folder on the charles node's hard drive


################ Setting up data shit #################
# echo 'Moving data from the cluster filesystem to the hard drive of the Charles node'
# # Zipped file on the cluster filesystem (glusterfs....slow!)
# source=/home/s0910166/git/cluster-scripts/slurm_templates/demo_data.tar.gz

# # Where we want to put data on the charles node's hard drive
# target=/disk/scratch/s0910166/data/demo_data.tar.gz

# rsync -ua --progress ${source} ${target}  # copy data from source to target location
#                                           # (will only do it if it needs to)

# # target_unzipped=${target%%.*}
# target_unzipped=/disk/scratch/s0910166/data/demo_data
# if [ -d "$target_unzipped" ]; then
#     echo "Assuming zip already extracted..."
# else
#     echo "Extracting zip..."
#     tar xvzf ${target}
# fi


############### The actual job! ##################
# Activate the relevant virtual environment
echo "Activating virtual environment"
conda activate mvtsc

# Run the python script that will train our network
python_command=${@:1}
COMMAND="python ${python_command}"
echo "Running provided command: $COMMAND"
eval "$COMMAND"

echo "============"
echo "job finished successfully"