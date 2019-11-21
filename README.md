# Useful scripts for the CDT cluster

A collection of scripts for:
* getting the status of the cluster: `cluster-status`, `gpu-usage`, `free-gpus`, `down-gpus`, `whoson`
* information about running jobs: `jobinfo`, `longbois`
* and aiding your job submission: `interactive`, `killmyjobs`, `onallnodes`

They mainly just parse the output of slurm commands, so should be easy to read and understand. The [documentation for slurm](https://slurm.schedmd.com/), in particular the [man pages](https://slurm.schedmd.com/man_index.html), explain all the options.

## Setup

Place these scripts in a folder and add that folder to your path e.g.

```{bash}
cd ~
mkdir git
cd git
git clone https://github.com/cdt-data-science/cluster-scripts.git
echo 'export PATH=/home/$USER/git/cluster-scripts:$PATH' >> ~/.bashrc
source ~/.bashrc
```

If instead of cloning the repo, you copied the files to a directory manually, make sure they are executable:
```{bash}
chmod u+x {cluster-status,down-gpus,free-gpus,gpu-usage,gpu-usage-by-node,whoson,jobinfo,longbois,interactive,killmyjobs,onallnodes} 
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

If you want to have job ID autocompletion for `scancel`, you need to source the `job-id-completion.sh` script:

```{bash}
cd ~
echo "source /home/$USER/git/cluster-scripts/job-id-completion.sh" >> ~/.bashrc
source ~/.bashrc
```

## Examples

* Get an interactive session
```
(base) [albert]s0816700: interactive
Doing a --test-only to estimate wait time...
srun: Job 455329 to start at 2019-05-01T14:56:10 using 1 processors on charles12

Running the following command to get you an interactive session:
srun --time=01:00:00 --mem=2000 --cpus-per-task=1 --pty bash

(base) [charles12]s0816700: 
```

* Quickly identify free gpus for use
```
(mg) [albert]s0816700: ./free-gpus 
datetime             nodename   in_use  usable  total
19/04/2019 10:47:43  charles01  1       2       2
19/04/2019 10:47:43  charles02  0       2       2
19/04/2019 10:47:43  charles07  0       2       2
19/04/2019 10:47:43  charles08  0       2       2
19/04/2019 10:47:43  charles09  0       2       2
19/04/2019 10:47:43  charles10  0       2       2
19/04/2019 10:47:43  charles14  3       4       4
19/04/2019 10:47:43  charles17  3       4       4
19/04/2019 10:47:43  charles19  3       4       4
```

* View whether nodes are down and why
```
(mg) [albert]s0816700: ./down-gpus 
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
(mg) [albert]s0816700: ./whoson
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

* Kill all your jobs
```
# Launch some jobs
some_script=/mnt/cdtds_cluster_home/s0816700/git/melody_gen/scripts/slurm_blankjob.sh
for ii in {1..8}; do 
  sbatch --time=05:00 --nodelist=charles01 --cpus-per-task=8 --mem=2000 $some_script 100
done
```

```
# Kill em
killmyjobs
> killing jobs in queue as well as running jobs
> killing 454218 454219 454220 454221 454214 454215 454216 454217
```

or

```
# Only kill ones running (leave ones in queue alone)
killmyjobs -g
> not killing jobs in queue
> killing 454206 454207 454208 454209
```

* Run a job on every node in the cluseter - useful for something like changing data on scratch spaces
```
some_script=/mnt/cdtds_cluster_home/s0816700/git/melody_gen/scripts/slurm_diskspace.sh
onallnodes $some_script
```

The scripts in the gridengine directory are from the previous scheduler sytem, and won't work with SLURM.
