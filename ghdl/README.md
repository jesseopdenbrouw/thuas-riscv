
# Simulation using GHDL

It is possible to simulate the design using GHDL
and viewing the results using GTKWave.

## Usage

* `make` - compiles and simulates the design, and starts the GTKWave to show the waveforms,
* `make run` - compiles and simulates the design, does not start GTKWave and doesn't produce a wave file, useful for embedded output (`assert`, `report`),
* `make clean` - cleans the directory.

## Notes

Running with a simulation time more than 10 ms seriously slows down display with GTKwave.

