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
1. First, set up your environment on the cluster. Follow the section entitled
"Quick Bash Environment Setup" here: http://bit.ly/37p2BLZ
1. If you haven't already, clone this repository, following the
[base README.md](../../../README.md) installation instructions to make all the
executables available, such as `interactive_gpu`
1. Make `run_experiment` available by running the setup instructions in the
[slurm experiments README](../../README.md) in the base directory for slurm
experiments
1. **IMPORTANT** Create a folder for your log files. For this example we are
using `/home/${USER}/slurm_logs`. If you want to change that in future, make
sure you change the lines `#SBATCH --output ...` and `#SBATCH --error ...` - if
the directories do not exist **`sbatch` will silently fail!**
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
The python script [`./main.py`](main.py) runs an mnist experiment. First oF
all, read the code and spend 5 minutes or so trying to understand what it does:
[`./main.py`](main.py). There's no need to be too thorough, we're going to walk
through the basics below.

### Log on to a node with a GPU
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


## 2. Create the `mnist_arrayjob.sh` - the bash script for the slurm arrayjob
We need to make a bash script to pass to `sbatch` which will essentially do
exactly what we did above interactively:
* Activate the conda enviroment
* Create our scratch input data directory (if required)
* Move data from DFS to scratch (if required)
* Select the experiment command
* Run the experiment
* Copy output data back to DFS

We have made [`mnist_arrayjob.sh`](mnist_arrayjob.sh) for you! Do take a look
at it, and make sure you understand how it is slecting lines from
`experiment.txt`.


## 3. Create `experiment.txt` - the commands to run
Again, we've given you a helping hand here and given you a script to generate
`experiment.txt`. Have a look at gen_experiment.py](gen_experiment.py) in your
browser or `cat gen_experiment.py` in your terminal.

In your terminal, change the directory to here, and run the script to make
the experiment file. Have a look at the file!
```
cd $repo_home/experiments/examples/mnist
python gen_experiment.py
head experiment.txt
wc experiment.txt
```

## 4. Run your experiment!
We're ready to run it. If everything was left as it, we're going to run 60
experiments, capping it at 10 experiments at a time.

You can do it the long way...
```
EXPT_FILE=experiments.txt
NR_EXPTS=`cat ${EXPT_FILE} | wc -l`
MAX_PARALLEL_JOBS=10
sbatch --array=1-${NR_EXPTS}%${MAX_PARALLEL_JOBS} mnist_arrayjob.sh $EXPT_FILE
```

...or the short way we've made for you!
```
run_experiment -b mnist_arrayjob.sh -e experiment.txt
```

To observe your jobs running, you can execute:
```
myjobs  # shorthand for squeue -u ${USER}
# or if you want to see it in real time
watch myjobs  # hit ctrl-c to exit
```

We set a location for our logs this time, so go there and have a look:
```
ls ~/slurm_logs
cat ~/slurm_logs/slurm-*
```

To watch a log as it progresses, you can use tail -f to "follow":
```
tail -f ~/slurm_logs/slurm-665999_1.out 
```

Bear in mind that, by default, to save on network traffic, slurm will only
write back to the log in chunks. You can bypass this in your scripts by forcing
the stdout to 'flush'.

Eventually, you should start seeing your results sent back to the DFS e.g.:
```
ls data/output
> 64_10.0_0.4_1547420631.best.pt	 64_10.0_0.6_438938989.log	  64_10.0_0.8_1871285932.final.pt  64_1.0_0.5_2668691076.best.pt
> 64_10.0_0.4_1547420631.final.pt  64_10.0_0.6_679712202.best.pt	  64_10.0_0.8_1871285932.log	   64_1.0_0.5_2668691076.final.pt
> 64_10.0_0.4_1547420631.log	 64_10.0_0.6_679712202.final.pt   64_10.0_0.8_818634812.best.pt    64_1.0_0.5_2668691076.log
```

## 5. Checkpointing
But what happens if an experiment fails? A node on the cluster can fail at any
time...and they do with regularity :upside_down_face:. We need to write our
code such that:
* a job could fail at any time and it doesn't matter - we can pick up where we
left off
* we can keep our jobs on the cluster **short**

If you execute `sinfo` in your terminal, you'll see that there are likely time
limits on how long your job should run:
```
$ sinfo -o '%R;%N;%l' | column -s';' -t
PARTITION          NODELIST                           TIMELIMIT
Teach-Interactive  landonia[01,03,25]                 2:00:00
Teach-Standard     landonia[04-10,12-17,19-20,22-24]  8:00:00
Teach-Short        landonia[02,18]                    4:00:00
Teach-LongJobs     landonia[11,21]                    3-08:00:00
General_Usage      letha[01-06]                       3-08:00:00
PGR-Interactive    damnii01                           2:00:00
PGR-Standard       damnii[02-12]                      7-00:00:00
```

Even if there isn't a limit, it is much more curteous to other users for your
jobs to take no more than 8 hours. It's not a very good situation to have one
person take over the nodes with jobs lasting a month each.

To implement checkpointing you need to:
1. edit [./main.py](main.py):
    1. Make a new argument which is the path to a *.pt file, if it's not
    specified then don't load a model
    1. With that argument, try to load a model at the beginning of the script.
    It's useful to allow the path not to exist; if it doesn't exist, don't load
    a model from the checkpoint.
    1. https://pytorch.org/tutorials/beginner/saving_loading_models.html this
    might be useful
    1. this is going to mess up your logging unless you additionally read the 
    log file associated with the checkpoint file. Luckily they have (nearly)
    the same name, so you should be able to do this. Read the epoch number from
    the log file if loading a checkpoint, and begin at the next epoch and
    continue --epoch number of epochs
1. edit [./gen_experiment.py](gen_experiment.py)
    1. add this new argument to the experiment.txt generation file. You should
    try and load a checkpoint if it exists by default.
    1. Be careful about paths: where do we want to load the checkpoint from?
1. Is there anything you would need to change in
[mnist_arrayjob.sh](mnist_arrayjob.sh)?


## 6. Extension challenges
You've got all your ouptut, now you want to analyse it. See if you can write
code to do the following:
1. Find the best model
1. Find the worst model!
1. Plot the train and test curves for every model fitted
1. Implement early stopping in your models - you don't want to keep triaing if
your validation loss is not improving
