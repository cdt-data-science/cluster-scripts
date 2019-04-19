# Useful scripts for the CDT cluster

Scripts in the root directory use slurm commands and their outputs to get cluster status in a nice format.
## Examples

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

The scripts in the gridengine directory are from the previous scheduler sytem, and won't work with SLURM.

## Setup

Place these scripts in a folder and add that folder to your path e.g.

```{bash}
cd ~
mkdir git
cd git
git clone https://github.com/cdt-data-science/cluster-scripts.git
echo "export PATH=/home/$USER/git/cluster-scripts:\$PATH" >> ~/.bashrc
source ~/.bashrc
```

If instead of cloning the repo, you copied the files to a directory manually, make sure they are executable:
```{bash}
chmod u+x {cluster-status,down-gpus,free-gpus,gpu-usage,gpu-usage-by-node,whoson} 
```

You should now be able to run the scripts from anywhere when on the cluster.
