#!/bin/bash

# ====================
# Activate Anaconda environment
# ====================
source /home/${USER}/miniconda3/bin/activate pt

for i in {1..50}
do
   echo "${i}"
   sleep 1
done

# ====================
# Run really simple program
# ====================
python src/simple.py

echo "Done!"
