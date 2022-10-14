# ILCC Cluster Demo -- Working with Slurm 
#### Tom Sherborne (adapted from James Owers)
##### 13/15th October 2021

### Agenda:
* What is `cluster-scripts`?
* Opening up the ILCC Cluster
* `squeue` and `sinfo`
* Requesting an interactive session with `interactive` or `interactive_gpu`
* Checking your GPU allocation with `nvidia-smi`
* A simple example experiment without a GPU using `simple_experiment.sh`
* Submitting and monitoring a Slurm job
* A more advanced experiment with a GPU using `advanced_experiment.sh`
* Monitoring the advanced job
* Logging files and console output


### Getting setup:

**Note**: read the [ILCC Cluster Quick Start Guide](../../guides/) and [ILCC Cluster Talk](../../guides/) **first** before this `README.md`. This `README.md` is meant to cover the **demo** part of the introductory lecture. 

As a rule of thumb, we shouldn't ever run process on the headnode (`escience6.inf.ed.ac.uk`). This includes the CPU and disk intensive process of creating a Conda environment. But it can be difficult to install Conda from a compute node so we will do this just once.

1. Install miniconda3 (ideally this should have already been done _or_ see below.)
2. Create a new Python environment called `pt`:
```
conda create -y -n pt python=3 pytorch torchvision torchaudio cudatoolkit=11.3 -c pytorch
```
This should take about 10 minutes, but might be longer (especially since many of us are running this).


### What is `cluster-scripts`?

This repository is designed to help you out getting started and using Informatics clusters. Originally, it was created for Data Science CDT students but we have now mostly updated everything to work on any cluster (if something doesn't work, please let me know). 

See [`../../README.md`](../../README.md) for more information.

### Opening up the ILCC Cluster

Hopefully you are already here! You access the cluster via SSH like:
```
ssh ${USER}@ilcc-cluster.inf.ed.ac.uk # May need to enter your DICE password
```
If you are working from home or outside of DICE, then you will probably want to authenticate using a Kerberos ticket:
```
kinit ${USER}@INF.ED.AC.UK
>>> Enter password......
ssh -K ${USER}@ilcc-cluster.inf.ed.ac.uk # The -K means authenticate with your Kerberos ticket
```
After this, you will be logged onto `escience6` which is the machine name for the head node (`ilcc-cluster` and `escience6` are interchangeable).
```
s1833057@escience6:~$ # We are now logged in and ready to go
```

### `squeue` and `sinfo`

There are two useful commands that we will start looking at before we run a job.

1. [`squeue`](https://slurm.schedmd.com/squeue.html) - View information about jobs in the queue

This will list all the jobs running on the cluster and those that are waiting to run:

```
${USER}@escience6:~$ squeue | head
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            147054   CDT_GPU temp_slu s1785140  R   19:43:32      1 strickland
            147055   CDT_GPU temp_slu s1785140  R   19:43:32      1 strickland
            147056   CDT_GPU temp_slu s1785140  R   19:43:32      1 strickland
            147057   CDT_GPU temp_slu s1785140  R   19:43:32      1 strickland
            147058   CDT_GPU     bash s2004019  R   19:43:14      1 strickland
            147140  ILCC_CPU     bash   lperez  R    3:08:39      1 stkilda
            147134  ILCC_CPU     bash   lperez  R    3:54:19      1 stkilda
            147127  ILCC_CPU     bash   lperez  R    4:28:40      1 bravas
            147126  ILCC_CPU     bash   lperez  R    4:33:23      1 bravas
           ...
```
The first column gives you the ID of the job (important for tracking which of your jobs is doing what), then additional columns will indicate the Partition (more on this in a moment), the name of the script submitted with `sbatch`, the user who owns the job, the job status, the job runtime and finally the list of nodes running the job. 

The `(REASON)` field is mostly useful to understand why a job is in the queue: 

    - `(Resources)` means there is nothing currently available that can run this job.
    - `(Priority)` means other jobs are more important.
    - `(ReqNodeNotAvail)` means a specific node is down so this job cannot start.

In each case, the `(REASON)` does **not** mean your job _won't run_, just that it is currently not running. Once the conditions of the reason are resolved, your job will execute. There is no reason to suspect that your job will be indefinitely held in a queue until the end of time. The exception to this is if you request a configuration that does not exist on the cluster -- building a feasible specification for your experiments is part of your job. 

If you want to see only **your own jobs**, then you can run:
```
squeue -u ${USER}
```

More arguments can be found in [the documentation]((https://slurm.schedmd.com/squeue.html)) or `man squeue`.


2. [`sinfo`](https://slurm.schedmd.com/sinfo.html) - View information about the cluster configuration

We have mentioned **partitions** briefly before, but what do they actually mean? Our clusters are organised into groups of nodes with different specifications and priorities. Considering the `ILCC Cluster`, what we actually are referring to is the a collection of servers (i.e. compute nodes) linked together with a controlling "head" node (this is the `escience6` machine). The servers (with GPUs attached) are organised into "partitions", or groups, which each have different access permissions. You will all have access to the `ILCC_*` and `CDT_GPU` partitions. 

If you want to get a good specification of a cluster, you can use `sinfo` to detail the partitions and nodes available:

```
${USER}@escience6:~$ sinfo
PARTITION   AVAIL  TIMELIMIT  NODES  STATE NODELIST
ILCC_GPU*      up 10-00:00:0      8    mix barre,duflo,greider,levi,mcclintock,moser,nuesslein,ostrom
CDT_GPU        up 10-00:00:0      1    mix strickland
CDT_GPU        up 10-00:00:0      1   idle arnold
ILCC_CPU       up 10-00:00:0      2    mix bravas,stkilda
ILCC_CPU       up 10-00:00:0      2   idle kinloch,rockall
M_AND_I_GPU    up 10-00:00:0      5    mix buccleuch,chatelet,davie,elion,yonath
M_AND_I_GPU    up 10-00:00:0      8   idle bonsall,gibbs,livy,nicolson,quarry,snippy,tangmere,tomorden
```

If you want even more detail, look at the `cluster-status` script in the main repository. 


### Requesting an interactive session with `interactive` or `interactive_gpu`

Now we are set up with a conda environment and we know how to check what jobs are running with `squeue`. Let us now investigate launching an interactive job to get direct access to a specific node in the `ILCC_GPU` partition. 

As discussed before, this can be done using the `srun` command like so (we have added in some sensible arguments):
```
$ srun --partition=ILCC_GPU --time=08:00:00 --mem=14000 --cpus-per-task=4 --pty bash
```
By running this, Slurm will assign you a session on a node in the partition:
```
...
srun: job 1292779 queued and waiting for resources
srun: job 1292779 has been allocated resources
(base) ${USER}@barre:~$ 
```
Remember that interactive sessions should only really be used for cleanup and debugging so I should _not_ start training my machine learning model after getting a session with `srun`. 

Lets look at some of the features of this session: 

- I can access the `/disk/scratch/` space for `barre`
```
${USER}@barre:~/cluster-scripts$ cd /disk/scratch/
${USER}@barre:/disk/scratch$
```
- An interactive session is still a job (that is actually running the shell command). I can see this in `squeue`
```
(base) ${USER}@barre:/disk/scratch$ squeue -u $USER
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
            147189  ILCC_GPU     bash s1833057  R       0:43      1 barre
```
- I _might_ be able to do some debugging of the model, but first I need to check my GPU access by running `nvidia-smi`
```
${USER}@barre:/disk/scratch$ nvidia-smi
No devices were found
```

This final command prints that no GPUs were found. The node still has GPUs, but our job has not been given access to them _because we did not ask for one_. To access a GPU, we need to remember the resource request argument `--gres=gpu:1`. Now look what happens if we re-run `srun` with this argument. You can exit this interactive session using `exit`. 

```
$ srun --partition=ILCC_GPU --time=08:00:00 --mem=14000 --cpus-per-task=4 --gres=gpu:1 --pty bash
```

Now if we check for GPUs, we can see we have access to one (device #0):

```
$ nvidia-smi
```

In this state, logged into a node with a GPU, we could start debugging a model that isn't working properly or prototype an experiment before submitting to `sbatch`. We will now look at submitting and monitoring jobs. 


### A simple example experiment without a GPU using `simple_experiment.sh`

Have a look at `simple_experiment.sh` which is a bash script running a really simple blob of Python code. We will try and run this example using `sbatch` just to get a feel for what happens when we submit a job. 

To submit a job (assuming you are inside the `experiments/examples/nlp` directory):
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
sbatch -N 1 -n 1 --mem=2000 --partition=ILCC_GPU -t 12:00:00 --cpus-per-task=2 simple_experiment.sh

# -N is number of nodes
# -n is number of requested tasks
# --mem is the RAM requirement in MB
# --partition tells Slurm to put this into the selected cluster
# -t is the requested job time (ILCC Cluster jobs have a max time of 10 days)
# --cpus-per-task is the number of CPU cores for your task (Careful not to use all the CPUs on a machine)
```

### Submitting and monitoring a Slurm job

If you run `ls` in your current directory, you will find a new file called `slurm-XXXX.out`. Since your job is running now as a background process on a compute node, the logs are no longer output to the SSH session. Slurm redirects all the console logs from your job to this file. If you run this file through `cat`, you will see all the logs (`stdout` and `stderr`) since the job started.

We can monitor the job as it happens using `watch`:

```
watch -n 0.5 tail -n 30 slurm-1292804.out
```

### A more advanced experiment with a GPU using `advanced_experiment.sh`

Now look at `advanced_experiment.sh`, which is more complicated and better demonstrates the components we need in our Slurm jobs for Machine Learning. Notice the arguments at the start beginning with `#SBATCH` -- this is a convenient way to pack your submission arguments into your experiment script without having to give them when you run `sbatch` as we did above.

We can try submitting this script using `sbatch` as above:
```
mkdir -p /home/${USER}/slogs
sbatch advanced_experiment.sh
```
As before, Slurm will notify us of a Job ID for monitoring. However, this won't appear in your current directory as we have created a new place for Slurm logs at `/home/${USER}/slogs/`. This is often more convenient than having log files littering your user space. These files can get **big**, so it is worthwhile periodically flushing this folder. 

You can check this jobs progress using:
```
watch -n 0.5 tail -n 30 /home/${USER}/slogs/slurm-YYYY.out
```
This example requires a GPU and sometimes the cluster is busy so this might end up queued. Hopefully, we can see this job running in action but you might have to wait until the cluster quietens down!

### Finishing Up

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

