# Templates for running experiments with slurm
These templates and accompanying wrapper function `run_experiment.sh`
facilitate a simple framework for running batches of commands:
1. Make a file which contains a command to run on each line
2. Run every line in that file in parallel using a slurm `sbatch --array...`

The script `run_experiment.sh` is essentially a wrapper for the slurm command
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
   ${SLURM_ARRAY_TASK_ID}

That's it! For every project, you'll likely need to make a new bash script.
You will probably want to make many different experiment files for a single
project e.g. different grid searches over parameters, investigating
different models, or running all your baselines.


## Quickstart
For a fuller explanation of these steps, see below or check out the
`./example` directory for a full worked example.

1. add scripts in this directory to your path (essentially allows you to run
   `run_experiment.sh` from anywhere)
```
echo "export PATH=/home/$USER/git/cluster-scripts/slurm_templates:\$PATH" >> ~/.bashrc
source ~/.bashrc
```
2. copy the bash script template to your project's home directory and customise
   it for your use (i.e. fill in your own paths, change the data `rsync` etc.).
   An example is given here:
   [example/slurm_arrayjob.sh](example/slurm_arrayjob.sh)
```
code_dir=your/project/home/dir
cp slurm_arrayjob.sh.template ${code_dir}/slurm_arrayjob.sh
vim ${code_dir}/slurm_arrayjob.sh
```
3. create an experiment file; each line contains a command to execute which
   will run one of your experiments. Protip: it will likely be easiest, not to
   mention facilitate reproducibility, if you whip up a script which will
   generate this file for you (there's an example in the `example` directory)
```
python ${code_dir}/gen_experiments.py
ls ${code_dir}
    ...
    experiments.txt
    ...
```
4. run your experiment! e.g.
```
run_experiment.sh -t ${code_dir}/slurm_arrayjob.sh \\
    -e ${code_dir}/experiments.txt \\
    -m 12 --cpus-per-task=4 --gres=gpu:1 --mem=8000
```


## The experimental framework explained
In this section we explain a little about what's going on under the hood.

### Slurm
[Slurm](https://slurm.schedmd.com/) is the workload manager which is used on
most of the GPU clusters in informatics, and elsewhere. For example:
```
ssh ${USER}@cdtcluster.inf.ed.ac.uk  # 
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
cluster (or at least 'partition' of the cluster) should be more or less
identical such that the user can just request that a bunch of commands
is executed and slurm handles the distribution of work.

### sbatch
The command which selects the node to run your code on is called
[`sbatch`](https://slurm.schedmd.com/sbatch.html). It takes a bash script as
input and runs that on the node selected.

#### Underlying distributed filesystem
The `/home` filesystem on each node is identical - it is part of a distributed
filesytem (DFS). This is the same filesystem as the 'headnode'. The 'headnode'
is the node you arrived at when you logged in to the cluster, and likely where
you executed the `sbatch` command from.

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
[array jobs](https://slurm.schedmd.com/job_array.html).



### The bash script

### The experiment file


## Tips

### Testing

### Moving data

## FAQ & Gotchas

