#!/usr/bin/env sh
## Template for use with a file containing a list of commands to run
## Example call:
##     EXPT_FILE=experiments.txt  # <- this has a command to run on each line
##     NR_EXPTS=`cat ${EXPT_FILE} | wc -l`
##     MAX_PARALLEL_JOBS=4 
##     sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS} slurm_arrayjob_template.sh $EXPT_FILE

#SBATCH -o /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -e /mnt/cdtds_cluster_home/s0910166/slurm_logs/slurm-%A_%a.out
#SBATCH -N 1	  # nodes requested
#SBATCH -n 1	  # tasks requested
#SBATCH --gres=gpu:1  # use 1 GPU
#SBATCH --mem=14000  # memory in Mb
#SBATCH -t 2:30:00  # time requested in hour:minute:seconds
#SBATCH --cpus-per-task=4  # number of cpus to use - there are 32 on each node.
# #SBATCH --exclude=charles[12-18]

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
mkdir -p ${SCRATCH_HOME}
export TMPDIR=${SCRATCH_HOME}
export TMP=${SCRATCH_HOME}
# export DATA_HOME=$SCRATCH_HOME/data/mirex_p4p
# mkdir -p ${DATA_HOME}
export CLUSTER_HOME=/mnt/cdtds_cluster_home/${STUDENT_ID}
# export OUTPUT_DIR=${CLUSTER_HOME}/git/melody_gen/data/output

# HERE send your data from albert to scratch:
# Ok, so Antreas uses `rsync -ua --progress source target`
# Ah. but he says 'Ensure your files are packed in a large compressed file though'
# That's quite an important point actually. The filesystem is fast at transferring 'one large file' but dog slow at transferring 'many small files'. So make sure you're just moving a zip around


# Activate the relevant virtual environment
echo "Activating virtual environment"
conda activate mvtsc


# Run the python script that will train our network
experiment_text_file=$1
COMMAND="`sed \"${SLURM_ARRAY_TASK_ID}q;d\" ${experiment_text_file}`"
echo "Running provided command: $COMMAND"
eval "$COMMAND"

echo "============"
echo "job finished successfully"