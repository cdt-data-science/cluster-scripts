#!/usr/bin/env python
import sys
import random
import time
try:
    max_time = int(sys.argv[1])
except (IndexError, ValueError):  # set max time to 10 if no arg given (IndexError)
                                  # or arg doesn't convert to int (ValueError)
    max_time = 10
tt = random.randint(0, max_time)
print(f"ehrmagerd: {sys.argv}")
print(f'Ima wait: {tt} seconds')
time.sleep(tt)