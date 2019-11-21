#!/usr/bin/env python3
"""Script for generating experiments.txt"""
import os

# The home dir on the node's scratch disk
USER = os.getenv('USER')
# This may need changing to e.g. /disk/scratch_fast depending on the cluster
SCRATCH_DISK = '/disk/scratch'  
SCRATCH_HOME = f'{SCRATCH_DISK}/{USER}'

DATA_HOME = f'{SCRATCH_HOME}/simple/data'
base_call = f"python3 train.py -i {DATA_HOME}/input -o {DATA_HOME}/output"

learning_rates = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2]
weight_decays = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1]

settings = [(lr, wd) for lr in learning_rates for wd in weight_decays]

output_file = open("experiment.txt", "w")

for lr, wd in settings:    
    expt_call = (
        f"{base_call} "
        f"--lr {lr} "
        f"--weight_decay {wd}"
    )
    print(expt_call, file=output_file)

output_file.close()
