#!/usr/bin/python3

import matplotlib
#matplotlib.use("QtAgg")

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

import sys


# Read the file
try:
    df = pd.read_csv("address.csv", sep=";", skiprows=1, comment='#', header=None, names=["time_ns", "address"])
except:
    print("Data file not found, exiting!")
    sys.exit(1)

# Plot
plt.figure(figsize=(10, 5))

plt.step(df["time_ns"], df["address"], label="PC address", where="post")
#plt.plot(df["time_ns"], df["address"], label="address", marker='.', linestyle='none')

plt.gca().yaxis.set_major_formatter(
    FuncFormatter(lambda val, pos: f'0x{int(val):04X}')
)

plt.xlabel("Time (ns)")
plt.ylabel("PC Address")
plt.title("Simulation results")
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.show()
