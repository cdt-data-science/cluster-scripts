# Templates for running experiments with slurm
These templates and accompanying wrapper function `run_experiment`
facilitate a simple framework for running batches of commands:
1. Make a file which contains a command to run on each line
2. Run every line in that file in parallel using a slurm `sbatch --array...`

The script `run_experiment` is essentially a wrapper for the slurm command
`sbatch --array...`. It sets off all the jobs to run in parallel when you give
it:
1. *a text file* containing all the experiments you want to run, one experiment
   per line
1. *a bash script* which sets up the environment prior to running each of the
   lines in your experiment text file (e.g. moving data around, activating a
   virtual environment etc.). Each "job" in the array uses this bash script to
   read a single line of the experiment text file and execute it. The line to
   be read from the experiment file is determined by how many jobs have already
   been run by the `sbatch` command so far; this is stored as the variable
   `${SLURM_ARRAY_TASK_ID}`

That's it! For every project, you'll likely need to make a new bash script.
You will probably want to make many different experiment files for a single
project e.g. different grid searches over parameters, investigating
different models, or running all your baselines.

## Setup
Add the script(s) in this directory to your path (essentially allows you to run
`run_experiment` from anywhere):
```
echo 'export PATH=/home/$USER/git/cluster-scripts/experiments:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Quickstart
For a fuller explanation of these steps, see below or check out the
[`./examples`](examples) directory for fully worked examples e.g.:
* [./examples/simple](./examples/simple) - a mock gridsearch requiring
*no dependencies*, a **very** quick introduction
* [./examples/mnist](./examples/mnist) - conda + pytorch + GPUs real-life
gridsearch: can be easiliy edited and used as a basis for your experiments

The below explains usage of the template:

1. follow the setup above
2. copy `slurm_arrayjob.sh.template` to your project's home directory and
   customise it for your use:
```
code_dir=your/project/home/dir
cp slurm_arrayjob.sh.template ${code_dir}/slurm_arrayjob.sh
vim ${code_dir}/slurm_arrayjob.sh
```
3. create an experiment file; each line contains a command to execute which
   will run one of your experiments:
```
python ${code_dir}/gen_experiment.py
ls ${code_dir}
>    ...
>    experiment.txt
>    ...
cat experiment.txt 
> python3 train.py -i /data/input -o /data/output --lr 1e-06 --weight_decay 1e-06
> python3 train.py -i /data/input -o /data/output --lr 1e-06 --weight_decay 1e-05
> python3 train.py -i /data/input -o /data/output --lr 1e-06 --weight_decay 0.0001
> ...
```

4. run your experiment! e.g.
```
run_experiment -b ${code_dir}/slurm_arrayjob.sh \
    -e ${code_dir}/experiment.txt \
    -m 12 --cpus-per-task=4 --gres=gpu:1 --mem=8000
```


## The experimental framework explained
In this section we explain a little about what's going on under the hood.

### Slurm
[Slurm](https://slurm.schedmd.com/) is the workload manager which is used on
most of the GPU clusters in informatics, and elsewhere. For example:
```
ssh ${USER}@cdtcluster.inf.ed.ac.uk
ssh ${USER}@mlp.inf.ed.ac.uk
ssh ${USER}@ilcc-cluster.inf.ed.ac.uk
```

Additionally external clusters (which you can sign up to use) also use slurm:
* [JADE](https://computing.help.inf.ed.ac.uk/cluster-jade)
* [EDDIE](https://www.wiki.ed.ac.uk/pages/viewpage.action?spaceKey=ResearchServices&title=GPUs)
  (note that the filesystem setup is slightly different, so you will have to
  edit your bash script)

You'll find an up-to-date list on the computing support website:
http://computing.help.inf.ed.ac.uk/cluster-computing

Slurm is used where you have a 'cluster' of machines but you, the user, don't
want to worry about which machine to run your code on. Each 'node' in the
cluster (or at least 'partition' of the cluster'sa nodes) should be more or
less identical such that the user can just request that a bunch of commands
is executed and slurm handles the distribution of work.

### sbatch
The command which selects the node to run your code on is called
[`sbatch`](https://slurm.schedmd.com/sbatch.html). It takes a bash script as
input and runs that on the node selected.

### srun
[`srun`](https://slurm.schedmd.com/srun.html) is essentially the same as
`sbatch` except that it is interactive i.e. when you run it, it is the only
process you are running in the foreground. Conversely, when you run `sbatch`,
it schedules your job, and runs it in the background, so you can get on with 
other things. `srun` is useful for small scripts, and to get you an interactive
bash session with `srun --pty bash`.

#### Underlying distributed filesystem
The `/home` directory on each node is identical - it is part of the same
distributed filesytem (DFS). This is the same on the 'headnode' too. The
'headnode' is the node you arrived at when you logged in to the cluster, and
likely where you executed the `sbatch` command from.

**THE DISTRIBUTED FILESYSTEM IS SLOW** - it should be used for storing your
code. Each node has its own **scratch** directory, which is a seperate storage
**only connected to this node** (located at one of the followning locations: 
`/disk/{scratch,scratch_big,scratch_fast}`). This scratch disk **is fast**
(in comparison). 

**It's important to read/save data from the scratch space on the node**.
Therefore, in your bash script you supply to `sbatch` you should move data to
the scratch space if it isn't already there. Protip: use `rsync` to do this.

### Array jobs
The `sbatch` command can operate in a couple of modes: executing a bash script
once, or executing it in an 'array' some specified number of times **in 
parallel**. We call these 
[array jobs](https://slurm.schedmd.com/job_array.html). If you run your sbatch
command in array mode, you can use the environment variable 
`${SLURM_ARRAY_TASK_ID}`, the id number of the specific job number in the
array, to call out to another file, select a line, and run it. 

### Why Arrays
There are benefits to running your experiments like this:
1. You can change the maximum number of parallel jobs running at any given time
   after the job has started e.g. the command 
   `scontrol update ArrayTaskThrottle=36 JobId=450263` changes the number of
   parallel jobs of array job 450263 to 36
2. control - you can easily stop, pause, or restart a whole group of jobs. Most
importantly, you can easily kill the whole lot by referencing the single JOBID.
For example, if:
```
squeue -u ${USER}
>              JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
> 666105_[11-35%10] Teach-Sta slurm_ar s0816700 PD       0:00      1 (JobArrayTaskLimit)
>           666105_1 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia19
>           666105_2 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia19
>           666105_3 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia19
>           666105_4 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia19
>           666105_5 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia20
>           666105_6 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia20
>           666105_7 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia20
>           666105_8 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia20
>           666105_9 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia22
>          666105_10 Teach-Sta slurm_ar s0816700  R       0:04      1 landonia22
```
you can kill all your jobs using `scancel 666105`. If you were running
individual jobs (not in an array), they would all have different JOBIDs.

3. easy logging - for the same reason as above, i.e. the JOBIDs have the same
base for all jobs in the array, it's easy to check the logs for a whole suite
of experiments
4. reproducibility - you necessarily have a file containing exactly what
   commands you ran. If you use a version control system (you...are right?!)
   then you can easily commit these with the codebase at a given timepoint and
   return there any time you like
