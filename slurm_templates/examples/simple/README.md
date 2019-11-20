# Simple example

This example mocks up what your experimental setup might look up. We've
provided you with a file `train.py` which reads "data" and "trains" your
"model" :smirk:. We're going to conduct a fake gridsearch over some parameters.

Follow the excercise below. This illustrates the experiment framework and
should take you no more than 20 minutes to complete.


## Exercise
We're going to:
1. make a file `experiment.txt` which contains all the commands to run our
gridsearch. Each line is the command to run one setting of the gridsearch.
1. make a file `slurm_arrayjob.sh` which will be passed to the `sbatch`
command, and be run on the selected node

### 0. Setup and start an interactive session
Firstly, make sure you have made `run_experiment` available by running the
setup instructions in the [README](../README.sh) in the directory above here.

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
# We have set a maximum time and a few other constraints:
srun --time=02:00:00 --mem=4000 --cpus-per-task=1 --pty bash
```

When you are finished, execute the `exit` command to return to the headnode.

Tip - if the `srun` command is taking a long time to allocate you an
interactive session, run `sinfo` and estabish if you should use a specific
partition for this. For example:
```
$ sinfo
> PARTITION         AVAIL  TIMELIMIT  NODES  STATE NODELIST
> Teach-Interactive    up    2:00:00      3   idle landonia[01,03,25]
> ...
> PGR-Interactive      up    2:00:00      1  down* damnii01
> ...
$ srun --partition=PGR-Interactive ...
```

### 1. Make a python script to run an experiment `train.py`
We've made one for you! This will read data, configure the model, and return
results. Try running the file will different options to see how it works:
```
# edit this if you cloned the repo elsewhere
repo_dir=/home/$USER/git/cluster-scripts
cd $repo_dir/slurm_templates/examples/simple
# Running without any options should show the 'help'
python3 train.py
# Try setting some of the options
python3 train.py -i data/input -o data/output
```

### 2. Create experiment.txt - the commands to run
We have made a script which will generate this file for you. This is a good
idea for you to do in general because it's:
1. much quicker that copy pasting and editing
1. much *safer* that that too (it's reproducible!)
1. easy to make another one with slightly different settings

In your terminal, change the directory to here, and run the script to make
the experiment file. Have a look at the file!
```
cd $repo_dir/examples/simple
python3 gen_experiment.py
head experiment.txt
```

### 3. Create the slurm_arrayjob.sh - the bash script for the slurm arrayjob
Well actually...

![I LIED](data/input/spurious_data.gif)

...Because we've made one for you. Do have a look though; you should be able to
answer the following questions (answers at the bottom of the README, no
cheating!):
1. where is the data located on the distributed filesystem?
1. where does the python script read the data from?
1. how did the data get there?
1. does the data get moved every time?
1. why are these different places?
1. where is the output data?


Run your gridsearch



## Answers

1. where is the data located on the distributed filesystem?
    * Well...right here! Specifically, if you cloned this git repo to
    `~/git/cluster-scripts`, as recommended, this location has the same path
    on all the nodes, i.e.
    `/home/${USER}/git/cluster-scripts/slurm_templates/examples/simple/data/input.zip`
    points to the distributed filesystem whichever node you are on
1. where does the python script read the data from?
    * The scratch node of node which the job gets allocated to
1. how did the data get there?
    * In slurm_arrayjob.sh, `rsync` moves the zip file over, and `unzip`
    unzips the zip file
1. does the data get moved every time?
    * No. The option `-u` in `rsync` will only update the file if the version
    on the distributed filesystem in newer, or the file doesn't exist on the
    scratch disk.
    * Bonus. If the data is already unzipped, the `-n` flag on the `zip`
    command always opts not to overwrite existing files.
1. why are these different places?
    * The DFS is very slow to read and write to. Read your experiment data
    from the node's scratch disk, write your results there, and then copy the
    results over at the end of the job
1. where is the output data?
    * Well, it's contained both on the scratch disk of the node, and on the
    DFS. The last part of `slurm_arrayjob.sh` moves the data back to the DFS.