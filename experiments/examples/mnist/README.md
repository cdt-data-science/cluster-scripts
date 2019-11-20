# MNIST example

This example is a realistic setup and will take a few hours to complete.
However, much of that time will be passive, waiting for `conda` or data to
download.

We're going to ste-I mean _adapt_ code from the Pytorch examples repository
[here](https://github.com/pytorch/examples/tree/master/mnist), which runs a
single MNIST experiment, and use slurm to run a grid search over parameters.

This example will extend the [simple example](../simple) and additionally:
* use a conda virtual environment
* use GPU resources
* use large(ish) data

This exercise is much less verbose - it's assumed you already know the basics
or you have run through the [simple example](../simple).


# Setup
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
# with a gpu.

srun --time=08:00:00 --mem=000 --cpus-per-task=1 --gres=gpu:1 --pty bash
```

1. First, set up your environment on the cluster. Follow the bash environment
setup instructions here http://bit.ly/37p2BLZ.
1. If you haven't already, clone this repository, following the
[base README.md](../../../README.md) installation instructions.
1. Make `run_experiment` available by running the setup instructions in the
[slurm experiments README](../../README.md) in the base directory for slurm
experiments

