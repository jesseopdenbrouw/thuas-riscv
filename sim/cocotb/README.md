
# Simulation using cocotb

It is possible to simulate the design using [cocotb](https://www.cocotb.org/)
. The output is a ASCII readable file.
cocotb uses a simulator as a backend. Tested with QuestaSim and [nvc](https://www.nickg.me.uk/nvc/) as backend.
[GHDL](http://ghdl.free.fr/) cannot be used as this simulator does not export record members.

## Usage

* `make` - compiles and simulates the design
* `make clean` - cleans the directory.

## Notes

 You have to install the cocotb systems. See the website.

