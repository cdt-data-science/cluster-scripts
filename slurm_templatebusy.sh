#!/usr/bin/env sh
## Template for use with a file containing a list of commands to run
## Example call:
##     sbatch slurm_template.sh main.py mts_archive 1B3G mcnn _itr_13

#SBATCH -o /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -e /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -N 1      # nodes requested
#SBATCH -n 1      # tasks requested
#SBATCH --gres=gpu:3  # use 1 GPU
#SBATCH --mem=28000  # memory in Mb
#SBATCH -t 5:30:00  # time requested in hour:minute:seconds
#SBATCH --cpus-per-task=8  # number of cpus to use - there are 32 on each node.

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
echo 'Moving data from the cluster filesystem to the hard drive of the Charles node'
# Zipped file on the cluster filesystem (glusterfs....slow!)
dirname=mts_archive
source=/home/s0910166/git/DNNTSC/archives/${dirname}.zip

data_home=/disk/scratch/s0910166/data
mkdir -p ${data_home}

# Where we want to put data zip on the charles node's hard drive
target=${data_home}/${dirname}.zip


rsync -ua --progress ${source} ${target}  # copy data from source to target location
                                          # (will only do it if it needs to)

if [ -d "${data_home}/${dirname}" ]; then
    echo "Assuming zip already extracted..."
else
    echo "Extracting zip..."
    unzip ${target} -d ${data_home}
fi


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
