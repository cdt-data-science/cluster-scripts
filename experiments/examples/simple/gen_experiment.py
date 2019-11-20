#!/usr/bin/env python
"""

"""
import os

task_nr = 1
fmt = 'command'
high_level_expt_name = f'task{task_nr}'
out_dir = f'{code_dir}/output/{high_level_expt_name}'
if not os.path.exists(out_dir):
    os.makedirs(out_dir)
in_dir = '/disk/scratch/s0816700/data/acme'

epochs = 10000
early_stopping = 50
base_call = (
    f"python {code_dir}/baselines/train_task.py "
    f"--task {task_nr} "
    f"--input {in_dir} "
    f"--format {fmt} "
    f"--seq_len 1000 "
    f"--epochs {epochs} "
    f"--batch_log_freq None "
    f"--early_stopping {early_stopping} "
)

nr_repeats = 3
learning_rates = [1e-6, 1e-5, 1e-4]
weight_decays = [1e-6, 1e-5]
hiddens = [100, 250]
nr_expts = nr_repeats * len(learning_rates) * len(weight_decays) * len(hiddens)

nr_servers = 10
avg_expt_time = 60  # mins
print(f'Total experiments = {nr_expts}')
print(f'Estimated time = {(nr_expts / nr_servers * avg_expt_time)/60} hrs')

settings = [(lr, wd, hid, repeat) for lr in learning_rates 
            for wd in weight_decays for hid in hiddens 
            for repeat in range(nr_repeats)]

output_file = open(f"{code_dir}/slurm/experiments/"
                   f"{high_level_expt_name}_experiments.txt", "w")
for lr, wd, hid, repeat in settings:
    expt_name = f"{high_level_expt_name}__{lr}_{wd}_{hid}_{repeat}"
    log_file = f"{out_dir}/{expt_name}.log"
    model_outpath = f"{out_dir}/{expt_name}.checkpoint"
    
    expt_call = (
        f"{base_call} "
        f"--lr {lr} "
        f"--weight_decay {wd} "
        f"--hidden {hid} "
        f"--output {model_outpath} "
        f"--log_file {log_file}"
    )
    print(expt_call, file=output_file)

output_file.close()
