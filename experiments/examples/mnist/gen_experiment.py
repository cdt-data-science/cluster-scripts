#!/usr/bin/env python3
"""Script for generating experiments.txt"""
import os

# The home dir on the node's scratch disk
USER = os.getenv('USER')
# This may need changing to e.g. /disk/scratch_fast depending on the cluster
SCRATCH_DISK = '/disk/scratch'  
SCRATCH_HOME = f'{SCRATCH_DISK}/{USER}'

DATA_HOME = f'{SCRATCH_HOME}/mnist/data'
base_call = (f"python main.py -i {DATA_HOME}/input -o {DATA_HOME}/output "
             "--epochs 50")

repeats = 3
learning_rates = [10, 1, 1e-1, 1e-2]
gammas = [.4, .5, .6, .7, .8]

settings = [(lr, gam, rep) for lr in learning_rates for gam in gammas
            for rep in range(repeats)]
nr_expts = len(learning_rates) * len(gammas) * repeats

nr_servers = 10
avg_expt_time = 20  # mins
print(f'Total experiments = {nr_expts}')
print(f'Estimated time = {(nr_expts / nr_servers * avg_expt_time)/60} hrs')

output_file = open("experiment.txt", "w")

for lr, gam, rep in settings:   
    # Note that we don't set a seed for rep - a seed is selected at random
    # and recorded in the output data by the python script
    expt_call = (
        f"{base_call} "
        f"--lr {lr} "
        f"--gamma {gam}"
    )
    print(expt_call, file=output_file)

output_file.close()
