#!/bin/bash

# ====================
# Activate Anaconda environment
# ====================
source /home/${USER}/miniconda3/bin/activate pt

# ====================
# Run really simple program
# ====================
python src/simple.py

echo "Done!"
