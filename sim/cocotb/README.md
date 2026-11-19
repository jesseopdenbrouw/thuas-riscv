
# Simulation using cocotb

## Simulation of the SoC

It is possible to simulate the design using [cocotb](https://www.cocotb.org/).
The output is a ASCII readable file.
cocotb uses a simulator as a backend. Tested with QuestaSim and [nvc](https://www.nickg.me.uk/nvc/) as backend.
[GHDL](http://ghdl.free.fr/) cannot be used as this simulator does not export record members.

### Usage

* `make` - compiles and simulates the design
* `make clean` - cleans the directory.

## Simulation of the instruction addresses

It is possible to simulate the design and capture the addresses the PC is assigned to. 
This will give you an overview of the sequential accesses and jumps. The complementary
file `address_plot.py` plots the addresses in a graph. You need the `matplotlib` and
`pandas` libraries. The simulation output is found in the file `address.csv`. Note that
the addresses are printed in decimal format. In the plot, the addresses are in
hexadecimal, as you would expect.

### Usage

In the Makefile, set the simulator to `nvc` and select the Python file `address_top.py`
(don't enter the `.py`). Now run the simulator with `make`. After the simulation is
completed, start the Python script `address_plot.py` and wait for the graph to be
displayed. Please use `nvc` as this simulator is much faster then `questa`.

## Notes

You have to install the cocotb system. See the website.

