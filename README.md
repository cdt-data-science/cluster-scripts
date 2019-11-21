# Useful scripts for the CDT cluster

1. A collection of executable scripts for:
* getting the status of the cluster:
  * `cluster-status` - node information
  * `gpu-usage` - aggregate gpu use information
  * `gpu-usage-by-node` - gpu use information per node
  * `free-gpus` - location of free gpus and how many
  * `down-gpus` - location of gpus which are down, and full information
  * `whoson` - which users are logged on and running how many jobs
* information about running jobs:
  * `myjobs` - prints all your running jobs (`squeue -u ${USER}`)
  * `jobinfo` - information per user or node about running jobs
* and aiding your job submission:
  * `interactive` & `interactive_gpu`- gets you an interactive job on one of
  nodes with or without a gpu
  * `killmyjobs` - useful for clearing jobs (has facility to exclude some)
  * `onallnodes` - run a script on all or a selection of nodes (very useful for
  regular cleaning jobs etc.)
  * `sinline` - quickly run commands on specified node(s) inline and print
  output to terminal (as opposed to a log file)
2. Templates and a framework for running experiments:
  * [experiments](experiments) - template + executable, and README explanation
  of framework
  * [simple example](./experiments/examples/simple) - a mock gridsearch
  requiring *no dependencies*, a **very** quick and practical introduction to
  the framework
  * [mnist example](./experiments/examples/mnist) - conda + pytorch + GPUs
  'realistic' gridsearch: can be easiliy edited and used as a basis for your 
  experiments


## Setup
Make the scripts available in this folder runnable from anywhere by adding the
folder containing them to the path. We recommend you do this using git so that
you can recieve updates easily.

Follow these commands: 
```{bash}
cd ~
mkdir git
cd git
git clone https://github.com/cdt-data-science/cluster-scripts.git
echo 'export PATH=/home/$USER/git/cluster-scripts:$PATH' >> ~/.bashrc
source ~/.bashrc
```

You should now be able to run the scripts from anywhere when on the cluster.
To check that this has worked, go somewhere else, then try some commands. For
example:
```
cd ~
gpu-usage -p
> in_use  usable  total  free
> 69      71      71     2
```

If you want to have job ID autocompletion for `scancel`, you need to source the
`job-id-completion.sh` script:
```{bash}
cd ~
echo "source /home/$USER/git/cluster-scripts/job-id-completion.sh" >> ~/.bashrc
source ~/.bashrc
```

## Example usage
These examples expect you to have followed the setup.

* Get an interactive session
```
$ interactive
Doing a --test-only to estimate wait time...
srun: Job 455329 to start at 2019-05-01T14:56:10 using 1 processors on charles12

Running the following command to get you an interactive session:
srun --time=01:00:00 --mem=2000 --cpus-per-task=1 --pty bash

(base) [charles12]s0816700: 
```

* Quickly identify free gpus for use
```
$ free-gpus 
datetime             nodename   free
21/11/2019 19:39:03  charles01  2

```

* View whether nodes are down and why
```
$ down-gpus 
datetime             nodename   in_use  usable  total
19/04/2019 10:49:12  charles03  0       0       2

Full cluster status:
NODELIST   GRES   STATE  TIMESTAMP            REASON                         FREE_MEM/MEMORY  CPU_LOAD
charles01  gpu:2  mixed  Unknown              none                           14101/60000      5.13
charles02  gpu:2  idle   Unknown              none                           18125/60000      0.01
charles03  gpu:2  down*  2019-04-19T10:05:53  forgot to check scratch mount  60915/60000      0.05
charles04  gpu:2  mixed  Unknown              none                           11713/60000      0.15
charles05  gpu:2  mixed  Unknown              none                           29526/60000      0.02
charles06  gpu:2  mixed  Unknown              none                           22375/60000      0.01
charles07  gpu:2  idle   Unknown              none                           11029/60000      0.01
charles08  gpu:2  idle   Unknown              none                           9622/60000       0.01
charles09  gpu:2  idle   Unknown              none                           22869/60000      0.01
charles10  gpu:2  idle   Unknown              none                           22897/60000      0.01
charles11  gpu:4  mixed  Unknown              none                           15546/60000      5.44
charles12  gpu:4  mixed  Unknown              none                           542/60000        5.08
charles13  gpu:3  mixed  Unknown              none                           20867/60000      3.73
charles14  gpu:4  mixed  Unknown              none                           12323/60000      2.94
charles15  gpu:4  mixed  Unknown              none                           5173/64328       5.83
charles16  gpu:4  mixed  Unknown              none                           1550/64328       6.07
charles17  gpu:4  mixed  Unknown              none                           8370/64328       1.38
charles18  gpu:4  mixed  Unknown              none                           3693/64328       3.08
charles19  gpu:4  mixed  Unknown              none                           24555/64328      7.16
```

* Identify people running jobs currently and their usage
```
$ whoson
sid       name                nr_jobs
s1234456  Bob smith           2
s8765423  Joe Bloggs          1
```

* Get information about jobs running on a node
```
jobinfo -n charles04
> JobId=452332 JobName=...
>    UserId=... GroupId=... MCS_label=N/A
>    Priority=1027 Nice=0 Account=... QOS=normal
>    JobState=RUNNING Reason=None Dependency=(null)
>    Requeue=1 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
>    RunTime=9-10:22:17 TimeLimit=UNLIMITED TimeMin=N/A
>    SubmitTime=2019-04-17T12:18:35 EligibleTime=2019-04-17T12:18:35
>    StartTime=2019-04-17T12:18:35 EndTime=Unknown Deadline=N/A
>    PreemptTime=None SuspendTime=None SecsPreSuspend=0
>    LastSchedEval=2019-04-17T12:18:35
>    Partition=cdtgpucluster AllocNode:Sid=albert:82878
>    ReqNodeList=(null) ExcNodeList=(null)
>    NodeList=charles04
>    BatchHost=charles04
>    NumNodes=1 NumCPUs=2 NumTasks=1 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
>    TRES=cpu=2,mem=14000M,node=1,billing=2,gres/gpu=1
>    Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
>    MinCPUsNode=1 MinMemoryNode=14000M MinTmpDiskNode=0
>    Features=(null) DelayBoot=00:00:00
>    Gres=gpu:1 Reservation=(null)
>    OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
>    Command=...
>    WorkDir=...
>    StdErr=...
>    StdIn=/dev/null
>    StdOut=...
>    Power=
```

* Kill all your jobs (except 1)
```
$ # Launch some jobs
$ parallel 'sbatch --nodelist=charles02 --time=05:00 --cpus-per-task=1 --mem=2000 --wrap "sleep 30" --job-name=sleeping{}' ::: {1..10}
Submitted batch job 610800
Submitted batch job 610801
Submitted batch job 610802
Submitted batch job 610803
Submitted batch job 610804
Submitted batch job 610805
Submitted batch job 610806
Submitted batch job 610807
Submitted batch job 610808
Submitted batch job 610809
$ myjobs
  JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
 610800 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610801 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610802 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610803 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610804 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610805 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610806 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610807 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610808 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 610809 cdtgpuclu sleeping s0816700  R       0:04      1 charles02
 
$ # Kill em
$ killmyjobs -e 610809
killing jobs in queue as well as running jobs
excluding 610809
killing 610800 610801 610802 610803 610804 610805 610806 610807 610808
```

or

```
$ # Only kill ones running (leave ones in queue alone)
$ killmyjobs -g
not killing jobs in queue
killing 454206 454207 454208 454209
```

* Run a job on every node in the cluster - useful for something like changing
data on scratch spaces
```
some_script=/mnt/cdtds_cluster_home/s0816700/git/melody_gen/scripts/slurm_diskspace.sh
onallnodes $some_script
```

* Quickly run commands on nodes inline and return output to console
```
for ii in {06..08}; do
  echo --------
  echo damnii$ii
  sinline -n damnii$ii \
    -c 'du -sh /disk/scratch/* 2>/dev/null | sort -rh' \
    -s '--partition=PGR-Standard'
done
> --------
> damnii06
> Submitted batch job 666168
> 108K	/disk/scratch/bob
> 4.0K	/disk/scratch/greg
> 4.0K	/disk/scratch/alice
> --------
> damnii07
> Submitted batch job 666169
> 428K	/disk/scratch/bob
> 4.0K	/disk/scratch/greg
> 4.0K	/disk/scratch/alice
> --------
> damnii08
> Submitted batch job 666170
> 84M	/disk/scratch/bob
> 4.0K	/disk/scratch/greg
> 4.0K	/disk/scratch/veronica
> 4.0K	/disk/scratch/alice
```