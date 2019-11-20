# Simple example

This example mocks up what your experimental setup might look like: we're
going to conduct a gridsearch over some parameters.

Follow the exercise below. This illustrates the experiment framework and
should take you no more than 20 minutes to complete.


## Exercise
We're going to:
1. make a file `experiment.txt` which contains all the commands to run our
gridsearch. Each line is the command to run one setting of the gridsearch.
1. make a file `slurm_arrayjob.sh` which will be passed to the `sbatch`
command, and be run on the selected node

### 0. Setup and start an interactive session
Firstly, if you haven't already, clone this repository, following the
[base README.md](../../../README.md) installation instructions.

Next, make sure you have made `run_experiment` available by running the
setup instructions in the [slurm experiments README](../../README.md) in 
the base directory for slurm experiments.

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
interactive session, run `sinfo` and establish if you should use a specific
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
Well actually...

![I LIED](data/input/spurious_data.gif)

We've made one for you! This will read data, configure the model, and return
results. Have a look at the file you're going to run (either on the server with
e.g. `cat train.py` or in your browser [train.py](train.py)).

Try running the file with different options to see how it works:
```
# edit this if you cloned the repo elsewhere
repo_dir=/home/$USER/git/cluster-scripts
cd $repo_dir/experiments/examples/simple

# Print the man page
python3 train.py -h

# Set the input path and output path, with arguments -i and -o, and run!
python3 train.py -i data/input -o data/output

# You have just run an experiment! Check out what it did...
ls data/output
cat data/output/*

# Try running another experiment!
python3 train.py -i data/input -o data/output --lr 0.001
ls data/output
cat data/output/*

# Which learning rate was more accurate?!
```

You should be able to answer the following:
1. What are the arguments you can supply to `train.py`
1. Which arguments are optional, and what happens if you do not set them?

### 2. Create experiment.txt - the commands to run
So, we want to make a file which lists all the experiments you want to run, like
you were doing manually in step 1, but you want to do 1000s. We have made a
script which will generate this file for you. Generating your experiments.txt
file is a good idea for you to do in general because it's:
1. much quicker than manually writing, copy pasting, and editing
1. much *safer* (it's reproducible!)
1. easy to make another file with slightly different settings

Again have a look at the file you're going to run (either on the server with
e.g. `cat gen_experiment.py` or in your browser
[gen_experiment.py](gen_experiment.py)).

In your terminal, change the directory to here, and run the script to make
the experiment file. Have a look at the file!
```
cd $repo_dir/experiments/examples/simple
python3 gen_experiment.py
head experiment.txt
wc experiment.txt
```

You should be able to answer the following:
1. How many jobs are we going to run in our gridsearch
1. If each job was going to take around an hour, and we are able to run 10
   jobs in parallel at any given time, how long will the full experiment take
   to run


### 3. Create the slurm_arrayjob.sh - the bash script for the slurm arrayjob
So we could simply *run* experiments.txt (e.g. `bash experiments.txt`), and it
will run each experiment in sequence, one after the other... but that would be
very slow!

We're going to use slurm to schedule these experiments to run in parallel. This
way, the whole lot could take as little time as running just one.

The slurm command for sending jobs to the cluster's nodes is
[`sbatch`](https://slurm.schedmd.com/sbatch.html). At the most basic level, it
just takes a bash script from you and executes that same script on every node
it is sent to. We are going to use it in 'array mode'.

We need to make a bash script which:
1. configures any slurm options we want to use
1. moves data from the DFS to the node we're on to the scratch space of the
   node we are allocated
1. runs one of the lines in experiments.txt

You're in luck, because we have made you just such a script! Have a look at
[`slurm_arrayjob.sh`](./slurm_arrayjob.sh) and answer the following questions
(answers at the bottom of the README, no cheating!):
1. where is the data located on the distributed filesystem?
1. where does the python script read the data from?
1. how did the data get there?
1. does the data get moved every time?
1. why are these different places?
1. where is the output data?
1. what happens to the output data if you do a second run of the experiment?
1. how does the script run different lines of experiment.txt?


### 4. Run your experiment!
Finally, it's time to see it in action. To set off all the jobs, run:
```
sbatch --array=1-35%10 slurm_arrayjob.sh experiment.txt
```

To observe your jobs running, you can execute:
```
myjobs  # shorthand for squeue -u ${USER}
# or if you want to see it in real time
watch myjobs  # hit ctrl-c to exit
```

You'll find all the logs printed in the current working directory:
```
ls
cat slurm-*
```

A more general way of doing the above (which doesn't rely on you knowing the
number of lines in experiment.txt):
```
run_experiment -b slurm_arrayjob.sh -e experiment.txt
```

With any luck, you should now have all your results!
```
ls data/output
tail -n +1 data/output/*  # a little trick to print filenames and file contents
```

**CONGRATULATIONS!** You just used the cluster to run all your experiments!

You can delete your logs easily using:
```
rm slurm-*.log
```


## Answers

### 1.
1. What are the arguments you can supply to `train.py`
    * There are 4 arguments:
        * `-i INPUT` - path to read the input data from
        * `-o OUTPUT` - path output data should be written to
        * `--lr` - learning rate to use
        * `--weight_decay` - weight_decay to use
1. Which arguments are optional, and what happens if you do not set them?
    `--lr` and `--weight_decay` are optional. If you don't specify them the
    default values are used. The default values are 1e-4 and 0.01 respectively
    (you can find this specified in the script)

### 2.
1. How many jobs are we going to run in our gridsearch
    * 35 - 5 learning rates x 7 weight decays
1. If each job was going to take around an hour, and we are able to run 10
   jobs in parallel at any given time, how long will the full experiment take
   to run
    * It's a fair estimate to say 3.5 hours, but actually it will take 4 hours:
    when the 3rd batch of 10 concurrent jobs have finished, you've still got
    5 left over, which will still take an hour

### 3.
1. where is the data located on the distributed filesystem?
    * Well...right here! Specifically, if you cloned this git repo to
    `~/git/cluster-scripts`, as recommended, this location has the same path
    on all the nodes, i.e.
    `/home/${USER}/git/cluster-scripts/experiments/examples/simple/data/input.zip`
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
    * Well, the output for individual runs is contained on the scratch disk
    of the node, but the amalgamated outputs are sent back to the DFS. The
    last part of `slurm_arrayjob.sh` moves the data back to the DFS.
1. what happens to the output data if you do a second run of the experiment?
    * The scratch disk of each node will now have two files inside. However,
    when rsync looks at these two files and compares them with the files on the
    DFS, it will decide to only send the one newer file (as the older file on
    scratch will either be unchanged on the DFS, or a newer file will already
    exist on the DFS)
1. how does the script run different lines of experiment.txt?
    * The script takes one argument as input - the path to the experiment file.
    It uses the slurm environment variable ${SLURM_ARRAY_TASK_ID} - if you
    run the command `sbatch --array=3-14 ...`, the jobs will receive numbers
    3 to 14 inclusive. That number is stored in ${SLURM_ARRAY_TASK_ID} and
    accessible within each job. The script simply picks line number
    ${SLURM_ARRAY_TASK_ID} from the file experiments.txt and runs it.
