# Useful scripts for the CDT cluster

The scripts in the gridengine directory are from teh previous scheduler sytem, and won't work with SLURM.

## Setup

Place these scripts in a folder and add that folder to your path e.g.

```{bash}
cd ~
mkdir git
cd git
git clone https://github.com/cdt-data-science/cluster-scripts.git
echo "export PATH=/home/$USER/git/cluster-scripts:\$PATH" >> ~/.bash_profile
source ~/.bash_profile
```

If instead of cloning the repo, you copied the files to a directory manually, make sure they are executable:
```{bash}
chmod u+x {qcat,qhead,get-output-file,qtail,show-past-jobs,qusr,lessnew,watchnew}
```

You should now be able to run the scripts from anywhere when on the cluster.
