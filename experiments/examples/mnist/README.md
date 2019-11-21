# MNIST example

This example is a realistic setup and will take a few hours to complete.
However, much of that time will be passive, waiting for `conda` or data to
download.

We're going to ste-I mean _adapt_ code from the Pytorch examples repository
[here](https://github.com/pytorch/examples/tree/master/mnist), which runs a
single MNIST experiment, and use slurm to run a grid search over parameters.

This example will extend the [simple example](../simple) and additionally:
* use a conda virtual environment
* use GPU resources
* use large(ish) data
* show you how to make **checkpointed code**: code which is resilient to errors
and early termination - you can rerun your jobs and pick up from the previous
checkpoint

This exercise is much less verbose - it's assumed you already know the basics
or you have run through the [simple example](../simple).


## 0. Setup
**IMPORTANT NOTE:** Running processes locally i.e. here on the headnode (the
node you arrive at when you ssh to a given cluster) is **VERY BAD**! The
headnode is responsible for coordinating all the jobs for slurm; if we clog
it with lots of additional jobs, it will slow everything down for everyone.
Thankfully, it's easy to simply jump on one of the nodes in the cluster and
work from there - everything works the same as if you were on the headnode:
```
cluster_name=cdtcluster  # e.g. mlp or ilcc-cluster
ssh ${USER}@${cluster_name}.inf.ed.ac.uk

# Run this slurm command to be allocated to a node in the default partition
# with a gpu.
srun --time=08:00:00 --mem=14000 --cpus-per-task=2 --gres=gpu:1 --pty bash

# You can also use our shortcut command which essentially does the above!
interactive_gpu
```

### 0.1. Initial bash setup
1. First, set up your environment on the cluster. Follow the bash environment
setup instructions here http://bit.ly/37p2BLZ.
1. If you haven't already, clone this repository, following the
[base README.md](../../../README.md) installation instructions to make all the
executables available, such as `interactive_gpu`
1. Make `run_experiment` available by running the setup instructions in the
[slurm experiments README](../../README.md) in the base directory for slurm
experiments
1. **IMPORTANT** Create a folder for your log files. For this example we are
using /home/${USER}/slurm_logs, if you want to change that in future, make sure
you change the lines `#SBATCH --output ...` and `#SBATCH --error ...` - if the
directories do not exist **`sbatch` will silently fail!**
```
mkdir /home/${USER}/slurm_logs
```


### 0.2. Create a conda environment
In 0.1, you should have installed conda. We're going to make a virtual
environment specifically for this exercise. 

> If you already have an environment with pytorch and torchvision
> installed, you should be fine to use that - just go through all the scripts
> and change instances of `pt` for the name of your environment.

Unfortunately, all these commands take *considerably* longer to run on a
distributed filesystem than they do on your local machine, so get that 
tea/coffee making paraphernalia ready (/ do some of the other setup
concurrently!). This requires an internet connection. Whilst `cdtcluster` has
internet connection on all nodes, other clusters may not, for instance `mlp`
does not. If you are on a cluster with internet connection on all nodes, you
should get an interactive session first. If not, you will need to use the
headnode to set up your environment :upside_down_face:
```
# Times in comments are how long commands took to run on mlp.inf.ed.ac.uk
# TIP: add -y to update and create commands to bypass the confirmation steps

# ~20 minutes
conda update conda

# ~20 minutes
conda create -n pt python=3 pytorch torchvision cudatoolkit -c pytorch
```

The rest of the guide assumes you have made this enviroment and it is
activated.

```
conda activate pt
```

### 0.3. Download the data
Again, because nodes sometimes don't have an internet connection, we will first
download the data we need to the DFS. Again, we're going to have to do this on
the headnode, which is bad practice in general:
```
conda activate pt
# If you cloned the repo somewhere else, change this the following line
repo_home=/home/${USER}/git/cluster-scripts
cd ${repo_home}/experiments/examples/mnist
python download_data.py
ls data/input
> MNIST
```

For your own experiments, if data is available on the internet, you can use
[`wget`](https://www.gnu.org/software/wget/manual/wget.html) to download it. If
the data is available on the informatics network, you can use 
[`scp`](https://linux.die.net/man/1/scp) or 
[`rsync`](https://download.samba.org/pub/rsync/rsync.html).


## 1. Test and understand `main.py`
The python script `main.py` runs an mnist experiment. First of all, read the
code and spend 5 minutes or so trying to understand what it does:
[`./main.py](main.py). There's no need to be too thorough, we're going to walk
through the basics below.

### Get a GPU
Get yourself an interactive session with a gpu and try out `main.py` by
following these commands:
```
interactive_gpu
conda activate pt
repo_home=/home/${USER}/git/cluster-scripts
cd ${repo_home}/experiments/examples/mnist
```

### Move data
Get the data onto the scratch disk of this node (reading from DFS is bad!)
```
# You may need to change the following line depending on the cluster's setup
SCRATCH_DISK=/disk/scratch
dest_path=${SCRATCH_DISK}/${USER}/mnist/data/input
mkdir -p ${dest_path}
src_path=data/input
rsync --archive --update --compress --progress ${src_path}/ ${dest_path}
ls /disk/scratch/${USER}/mnist/data/input
> MNIST
```

### Run an experiment!
Print the script's help, then run it!
```
python main.py -h
input_dir=${SCRATCH_DISK}/${USER}/mnist/data/input
output_dir=${SCRATCH_DISK}/${USER}/mnist/data/output
python main.py -i ${input_dir} -o ${output_dir} --epochs 2 --seed 1337
```
With any luck, you should get a whole bunch of logging put to the terminal.
You just trained a CNN for MNIST!

### Observe results
The model objects and logs were put to the output directory you specified. You
should see something like this in the output directory now:
```
ls ${output_dir}
> 64_1.0_0.7_1337.best.pt  64_1.0_0.7_1337.final.pt  64_1.0_0.7_1337.log
cat ${output_dir}/64_1.0_0.7_1337.log
> epoch,trn_loss,trn_acc,vld_loss,vld_acc
> 1,0.2054106452604135,0.9383666666666667,0.06509593696594239,0.9797
> 2,0.08019214093834162,0.9768166666666667,0.039160140991210936,0.9874
```

Great! So that's one experiment run...now we want to perform a grid search over
the different parameters available in the script. To do this, we're going to
make a file containing all the experiments to run, then the bash script to
perform the setup that we did manually above (e.g. activate conda, and move 
data), plus pluck lines from our experiment file and run them.


## 2. Create `experiment.txt` - the commands to run


## 3. Create the `mnist_arrayjob.sh` - the bash script for the slurm arrayjob


## 4. Run your experiment!


## 5. Checkpointing

