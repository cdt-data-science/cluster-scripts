# ILCC Cluster Demo -- Working with Slurm 
#### Tom Sherborne (adapted from James Owers)
##### 13/15th October 2021

### Agenda:
* What is `cluster-scripts`?
* Opening up the PGR Cluster
* `squeue` and `sinfo`
* Requesting an interactive session with `interactive` or `interactive_gpu`
* Checking your GPU allocation with `nvidia-smi`
* A simple example experiment without a GPU using `simple_experiment.sh`
* Submitting and monitoring a Slurm job
* A more advanced experiment with a GPU using `advanced_experiment.sh`
* Monitoring the advanced job
* Logging files and console output


### Getting setup:

As a rule of thumb, we shouldn't ever run process on the headnode (`uhtred.inf.ed.ac.uk`). This includes the CPU and disk intensive process of creating a Conda environment. **However**, the nodes in the `mlp` cluster *do not have direct Internet access* so we can't download packages if we are logged into a node. 

1. Install miniconda3 (ideally this should have already been done _or_ see below.)
2. Create a new Python environment called `pt`:
```
conda create -y -n pt python=3 pytorch torchvision cudatoolkit=10.1 -c pytorch
```
This should take about 10 minutes, but might be longer (especially since many of us are running this).


### What is `cluster-scripts`?

This repository is designed to help you out getting started and using Informatics clusters. Originally, it was created for Data Science CDT students but we have now mostly updated everything to work on any cluster (if something doesn't work, please let me know). 

See `../../README.md` for more information

### Opening up the PGR Cluster

Hopefully you are already here! You access the cluster via SSH like:
```
ssh ${USER}@mlp.inf.ed.ac.uk # May need to enter your DICE password
```
If you are working from home or outside of DICE, then you will probably want to authenticate using a Kerberos ticket:
```
kinit ${USER}@INF.ED.AC.UK
>>> Enter password......
ssh -K ${USER}@mlp.inf.ed.ac.uk # The -K means authenticate with your Kerberos ticket
```
After this, you will be logged onto `uhtred` which is the machine name for the head node (`uhtred` and `mlp` are interchangeable).
```
s1833057@uhtred:~$ # We are now logged in and ready to go
```

### `squeue` and `sinfo`

There are two useful commands that we will start looking at before we run a job.

1. [`squeue`](https://slurm.schedmd.com/squeue.html) - View information about jobs in the queue

This will list all the jobs running on the cluster and those that are waiting to run:

```
s1833057@uhtred:~$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
           1292504 PGR-Stand susouhu. s2016005 PD       0:00      1 (Resources)
           1292505 PGR-Stand susouhu. s2016005 PD       0:00      1 (Priority)
           1292683 General_U train_le s1601283 PD       0:00      1 (ReqNodeNotAvail, UnavailableNodes:letha06)
           1292126 PGR-Stand train.sh s1601283  R 3-18:55:02      1 damnii04
           1292362 PGR-Stand train.sh s1601283  R 1-21:26:35      1 damnii12
           ...
```
The first column gives you the ID of the job (important for tracking which of your jobs is doing what), then additional columns will indicate the Partition (more on this in a moment), the name of the script submitted with `sbatch`, the user who owns the job, the job status, the job runtime and finally the list of nodes running the job. 

The `(REASON)` field is mostly useful to understand why a job is in the queue: 
    - `(Resources)` means there is nothing currently available that can run this job.
    - `(Priority)` means other jobs are most important.
    - `(ReqNodeNotAvail)` means a specific node is down so this job cannot start.


If you want to see only **your own jobs**, then you can run:
```
squeue -u ${USER}
```

2. [`sinfo`](https://slurm.schedmd.com/sinfo.html) - View information about the cluster configuration

We have mentioned partitions briefly before, but what do they actually mean? In short, our clusters are organised into groups of nodes with different specifications and priorities. When we consider the "PGR Cluster", what we actually are referring to is the `PGR-Standard` partition of the `mlp` cluster because the PGR Cluster **shares a head node** with other clusters (note that there are plans to change this in the future and PGR will have it's own head node). Only PGR students should be allowed to use the PGR cluster nodes, so we treat this as a separate cluster and don't think about the other nodes/partitions in the cluster. 

If you want to get a good specification of a cluster, you can use `sinfo` to detail the partitions and nodes available:

```
s1833057@uhtred:~$ sinfo
PARTITION                 AVAIL  TIMELIMIT  NODES  STATE NODELIST
Teach-Interactive            up    2:00:00      1  down* landonia25
Teach-Interactive            up    2:00:00      1   idle landonia03
Teach-Interactive            up    2:00:00      1   down landonia01
Teach-Standard*              up    8:00:00      1  down* landonia24
Teach-Standard*              up    8:00:00     14   idle landonia[04-06,08-10,12-16,20,22-23]
Teach-Short                  up    4:00:00      2   idle landonia[02,18]
Teach-LongJobs               up 3-08:00:00      5   idle landonia[07,11,17,19,21]
General_Usage                up 3-08:00:00      1  down* meme
General_Usage                up 3-08:00:00      1  alloc letha06
General_Usage                up 3-08:00:00      5   idle letha[01-05]
General_Usage_Interactive    up    2:00:00      1   idle letha01
PGR-Standard                 up 7-00:00:00      1  down* damnii05
PGR-Standard                 up 7-00:00:00      2  drain damnii[02,09]
PGR-Standard                 up 7-00:00:00      1    mix damnii06
PGR-Standard                 up 7-00:00:00      8  alloc damnii[01,03-04,07-08,10-12]
CDT_Compute                  up 7-00:00:00     17  down* james[05-21]
CDT_Compute                  up 7-00:00:00      4   idle james[01-04]
```

If you want even more detail, look at the `cluster-status` script in the main repository. 


### Requesting an interactive session with `interactive` or `interactive_gpu`

Now we are set up with a conda environment and we know how to check what jobs are running with `squeue`. Let us now investigate launching an interactive job to get direct access to a specific node in the `PGR-Standard` partition. 

As discussed before, this can be done using the `srun` command like so (we have added in some sensible arguments):
```
$ srun --partition=PGR-Standard --time=08:00:00 --mem=14000 --cpus-per-task=4 --pty bash
```
By running this, Slurm will assign you a session on a node in the partition:
```
...
srun: job 1292779 queued and waiting for resources
srun: job 1292779 has been allocated resources
s1833057@damnii06:~/cluster-scripts$ 
```
Remember that interactive sessions should only really be used for cleanup and debugging so I should _not_ start training my machine learning model after getting a session with `srun`. 

Lets look at some of the features of this session: 

- I can access the `/disk/scratch/` space for `damnii06`
```
s1833057@damnii06:~/cluster-scripts$ cd /disk/scratch/
s1833057@damnii06:/disk/scratch$
```
- An interactive session is still a job (that is actually running the shell command). I can see this in `squeue`
```
s1833057@damnii06:/disk/scratch$ squeue -u $USER
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
           1292779 PGR-Stand     bash s1833057  R       4:58      1 damnii06
```
- I _might_ be able to do some debugging of the model, but first I need to check my GPU access by running `nvidia-smi`
```
s1833057@damnii06:/disk/scratch$ nvidia-smi
No devices were found
```

This final command prints that no GPUs were found. The node still has GPUs, but our job has not been given access to them _because we did not ask for one_. To access a GPU, we need to remember the resource request argument `--gres=gpu:1`. Now look what happens if we re-run `srun` with this argument. You can exit this interactive session using `exit`. 

```
$ srun --partition=PGR-Standard --time=08:00:00 --mem=14000 --cpus-per-task=4 --gres=gpu:1 --pty bash
```

Now if we check for GPUs, we can see we have access to one (device #0):

```
$ nvidia-smi
```

In this state, logged into a node with a GPU, we could start debugging a model that isn't working properly or prototype an experiment before submitting to `sbatch`. We will now look at submitting and monitoring jobs. 


### A simple example experiment without a GPU using `simple_experiment.sh`

Have a look at `simple_experiment.sh` which is a bash script running a really simple blob of Python code. We will try and run this example using `sbatch` just to get a feel for what happens when we submit a job. 

To submit a job (assuming you are inside the `experiments/examples/pgr` directory):
```
sbatch simple_experiment.sh
```
This will add the job to the queue and report a Job ID for monitoring. 
```
sbatch simple_experiment.sh
Submitted batch job 1292804
```

We can also add arguments to `sbatch` to control the parameters of the job:
```
sbatch -N 1 -n 1 --mem=2000 --partition=PGR-Standard -t 12:00:00 --cpus-per-task=2 simple_experiment.sh

# -N is number of nodes
# -n is number of requested tasks
# -mem is the RAM requirement in MB
# --partition tells Slurm to put this into PGR Standard
# -t is the requested job time (PGR jobs have a max time of 7 days)
# --cpus-per-task is the number of CPU cores for your task (damnii nodes have 20 total)
```

### Submitting and monitoring a Slurm job

If you run `ls` in your current directory, you will find a new file called `slurm-XXXX.out`. Since your job is running now as a background process on a compute node, the logs are no longer output to the SSH session. Instead, Slurm redirects all the output from your job to this file. If you run `cat` on it, you will see all the output since the job started.

We can monitor the job as it happens using `watch`:

```
watch -n 0.5 tail -n 30 slurm-1292804.out
```

### A more advanced experiment with a GPU using `advanced_experiment.sh`

Now look at `advanced_experiment.sh`, which is more complicated and better demonstrates many of the component stages we need in our Slurm jobs for Machine Learning. Notice the arguments at the start beginning with `#SBATCH`, this is a convenient way to pack your submission arguments into your experiment script without having to give them when you run `sbatch` as we did above.

We can try submitting this script using `sbatch` as above:
```
mkdir -p /home/${USER}/slogs
sbatch advanced_experiment.sh
```
As before, Slurm will notify us of a Job ID for monitoring. However, this won't appear in your current directory as we have created a new place for Slurm logs at `/home/${USER}/slogs/`. This is often more convenient than having log files randomly all over your user space.

You can check this jobs progress using:
```
watch -n 0.5 tail -n 30 /home/${USER}/slogs/slurm-YYYY.out
```

This example requires a GPU and sometimes the cluster is busy so this might end up in queue. Hopefully, we can see this job running in action but you might have to wait until the cluster quietens down!

### Finishing up

We have gone through a basic example of how to get stuff running on the cluster with Slurm. There is plenty more to learn and get to grips with and _now_ is a much better time to do this instead of _right before that important conference deadline_. There are two other example experiments in this repo for you to have a look at which give a more rigorous experiment outline for your future work. Hopefully this demo has given you the tools to get started running everything on the cluster. 

Good luck!

==================================================================

#### Addendum: Installing `miniconda`
1. Download the installer:
```
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
```
2. Now run the installation by running:
```
bash Miniconda3-latest-Linux-x86_64.sh
```
At the first prompt reply yes i.e.
```
Do you accept the license terms? [yes|no]
>>> yes
```
At the second prompt simply press enter i.e.
```
Miniconda3 will now be installed into this location:
/home/sxxxxxxx/miniconda3

  - Press ENTER to confirm the location
  - Press CTRL-C to abort the installation
  - Or specify a different location below
```

